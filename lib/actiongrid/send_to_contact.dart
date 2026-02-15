import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Color primaryBlue = Color.fromARGB(255, 13, 71, 161);
Color secondaryBlue = Color.fromARGB(255, 21, 101, 192);

class SendToContactPage extends StatefulWidget {
  SendToContactPage({super.key});

  @override
  State<SendToContactPage> createState() => SendToContactPageState();
}

class SendToContactPageState extends State<SendToContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isLoading = false;
  bool _isSearching = false;
  double _currentBalance = 0.0;
  Map<String, dynamic>? _selectedRecipient;
  Map<String, dynamic>? _searchResult;
  String _searchType = 'username';
  String? _searchError;
  String _accountType = 'Main Account';
  String _accountNumber = '****';

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _recipientController.addListener(_searchRecipientLive);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _accountType = args['accountType'] ?? _accountType;
      _accountNumber = args['accountNumber'] ?? _accountNumber;
      if (args['accountBalance'] != null) {
        _currentBalance = args['accountBalance'];
      }
    }
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _currentBalance = (doc.data()?['account_balance'] ?? 0).toDouble();
      });
    }
  }

  Future<void> _searchRecipientLive() async {
    final value = _recipientController.text.trim().toLowerCase();
    if (value.isEmpty) {
      setState(() {
        _searchResult = null;
        _selectedRecipient = null;
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    Query query = FirebaseFirestore.instance.collection('users');
    if (_searchType == 'username') {
      query = query.where('username', isEqualTo: value);
    } else if (_searchType == 'phone') {
      query = query.where('phone', isEqualTo: value);
    } else {
      query = query.where('email', isEqualTo: value);
    }

    final snap = await query.limit(1).get();
    
    if (snap.docs.isEmpty) {
      setState(() {
        _searchResult = null;
        _searchError = 'No user found with this $_searchType';
        _isSearching = false;
      });
      return;
    }

    final data = snap.docs.first.data() as Map<String, dynamic>;
    final me = FirebaseAuth.instance.currentUser;
    if (data['uid'] == me?.uid) {
      setState(() {
        _searchResult = null;
        _searchError = 'You cannot send money to yourself';
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _searchResult = {
        'uid': data['uid'],
        'name': data['name'],
        'email': data['email'],
        'username': data['username'],
        'phone': data['phone'],
      };
      _searchError = null;
      _isSearching = false;
    });
  }

  void _selectRecipient() {
    if (_searchResult != null) {
      setState(() {
        _selectedRecipient = _searchResult;
        _searchResult = null;
      });
    }
  }

  void _clearRecipient() {
    setState(() {
      _selectedRecipient = null;
      _recipientController.clear();
      _searchResult = null;
      _searchError = null;
    });
  }

  Future<void> _sendMoney() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRecipient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a recipient')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || amount > _currentBalance) return;

    final confirmed = await _showConfirmDialog(amount);
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final batch = FirebaseFirestore.instance.batch();
      final ts = Timestamp.now();

      final senderRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final recipientRef = FirebaseFirestore.instance.collection('users').doc(_selectedRecipient!['uid']);

      batch.update(senderRef, {
        'account_balance': FieldValue.increment(-amount),
        'expenses': FieldValue.increment(amount),
      });

      batch.update(recipientRef, {
        'account_balance': FieldValue.increment(amount),
        'income': FieldValue.increment(amount),
      });

      batch.set(FirebaseFirestore.instance.collection('transactions').doc(), {
        'userId': user.uid,
        'type': 'debit',
        'amount': amount,
        'description': 'Sent to ${_selectedRecipient!['name']}',
        'category': 'Transfer',
        'timestamp': ts,
      });

      batch.set(FirebaseFirestore.instance.collection('transactions').doc(), {
        'userId': _selectedRecipient!['uid'],
        'type': 'credit',
        'amount': amount,
        'description': 'Received from ${user.email}',
        'category': 'Transfer',
        'timestamp': ts,
      });

      await batch.commit();
      if (mounted) _showSuccessDialog(amount);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmDialog(double amount) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send Rs ${amount.toStringAsFixed(2)} to:'),
            SizedBox(height: 8),
            Text(_selectedRecipient!['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('@${_selectedRecipient!['username']}', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Confirm')),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 20),
            Text('Transfer Successful!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Rs ${amount.toStringAsFixed(2)} sent to'),
            Text(_selectedRecipient!['name'], style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Done', style: TextStyle(color: primaryBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Send Money', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                SizedBox(height: 24),
                _buildSearchTypeSelector(),
                SizedBox(height: 16),
                _buildRecipientSection(),
                SizedBox(height: 12),
                if (_isSearching) ...[
                  Center(child: CircularProgressIndicator()),
                  SizedBox(height: 12),
                ],
                if (_searchError != null) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _searchError!,
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ],
                if (_searchResult != null && _selectedRecipient == null) ...[
                  _buildSearchResultCard(),
                  SizedBox(height: 12),
                ],
                if (_selectedRecipient != null) ...[
                  _buildSelectedRecipientCard(),
                  SizedBox(height: 20),
                ],
                _buildAmountSection(),
                SizedBox(height: 20),
                _buildNoteSection(),
                SizedBox(height: 30),
                _buildSendButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.send,
              color: Colors.white,
              size: 32,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transfer Money',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Send money to your contacts instantly',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTypeSelector() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _searchTypeButton('Username', 'username')),
          Expanded(child: _searchTypeButton('Phone', 'phone')),
          Expanded(child: _searchTypeButton('Email', 'email')),
        ],
      ),
    );
  }

  Widget _searchTypeButton(String label, String value) {
    final selected = _searchType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _searchType = value;
          _selectedRecipient = null;
          _searchResult = null;
          _searchError = null;
          _recipientController.clear();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey[600])),
        ),
      ),
    );
  }

  Widget _buildRecipientSection() {
    return TextFormField(
      controller: _recipientController,
      enabled: _selectedRecipient == null,
      decoration: InputDecoration(
        hintText: 'Enter $_searchType',
        prefixIcon: Icon(Icons.search, color: primaryBlue),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSearchResultCard() {
    return InkWell(
      onTap: _selectRecipient,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryBlue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.person, color: primaryBlue),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_searchResult!['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('@${_searchResult!['username']}', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: primaryBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedRecipientCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedRecipient!['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                Text('@${_selectedRecipient!['username']}', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: _clearRecipient,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: '0.00',
        prefixIcon: Icon(Icons.toll_rounded, color: primaryBlue),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) {
        final a = double.tryParse(v ?? '');
        if (a == null || a <= 0) return 'Invalid amount';
        if (a > _currentBalance) return 'Insufficient balance';
        return null;
      },
    );
  }

  Widget _buildNoteSection() {
    return TextFormField(
      controller: _noteController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Add a note',
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendMoney,
        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text('Send Money', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}