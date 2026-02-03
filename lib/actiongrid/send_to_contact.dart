import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color primaryBlue = Color.fromARGB(255, 13, 71, 161);
const Color secondaryBlue = Color.fromARGB(255, 21, 101, 192);

class SendToContactPage extends StatefulWidget {
  const SendToContactPage({super.key});

  @override
  State<SendToContactPage> createState() => SendToContactPageState();
}

class SendToContactPageState extends State<SendToContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isLoading = false;
  double _currentBalance = 0.0;
  Map<String, dynamic>? _selectedRecipient;
  String _searchType = 'username';

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
      setState(() => _selectedRecipient = null);
      return;
    }

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
      setState(() => _selectedRecipient = null);
      return;
    }

    final data = snap.docs.first.data() as Map<String, dynamic>;
    final me = FirebaseAuth.instance.currentUser;

    if (data['uid'] == me?.uid) {
      setState(() => _selectedRecipient = null);
      return;
    }

    setState(() {
      _selectedRecipient = {
        'uid': data['uid'],
        'name': data['name'],
        'email': data['email'],
        'username': data['username'],
        'phone': data['phone'],
      };
    });
  }

  Future<void> _sendMoney() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRecipient == null) return;

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
            title: const Text('Confirm Transfer'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Send \$${amount.toStringAsFixed(2)} to:'),
                const SizedBox(height: 8),
                Text(_selectedRecipient!['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('@${_selectedRecipient!['username']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
            ],
          ),
        ) ??
        false;
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
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            const Text('Transfer Successful!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('\$${amount.toStringAsFixed(2)} sent to'),
            Text(_selectedRecipient!['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done', style: TextStyle(color: primaryBlue)),
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
        title: const Text('Send Money', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAccountHeader(),
                const SizedBox(height: 24),
                _buildSearchTypeSelector(),
                const SizedBox(height: 16),
                _buildRecipientSection(),
                const SizedBox(height: 20),
                if (_selectedRecipient != null) ...[
                  _buildRecipientCard(),
                  const SizedBox(height: 20),
                ],
                _buildAmountSection(),
                const SizedBox(height: 20),
                _buildNoteSection(),
                const SizedBox(height: 30),
                _buildSendButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Paying from', style: TextStyle(color: Colors.white.withOpacity(0.85))),
        const SizedBox(height: 6),
        Text(_accountType, style: const TextStyle(color: Colors.white, fontSize: 18)),
        const SizedBox(height: 16),
        Text('\$${_currentBalance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildSearchTypeSelector() {
    return Row(children: [
      Expanded(child: _searchTypeButton('Username', 'username')),
      Expanded(child: _searchTypeButton('Phone', 'phone')),
      Expanded(child: _searchTypeButton('Email', 'email')),
    ]);
  }

  Widget _searchTypeButton(String label, String value) {
    final selected = _searchType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _searchType = value;
          _selectedRecipient = null;
          _recipientController.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
      decoration: InputDecoration(
        hintText: 'Enter $_searchType',
        prefixIcon: const Icon(Icons.search, color: primaryBlue),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildRecipientCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.person, color: Colors.green),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_selectedRecipient!['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('@${_selectedRecipient!['username']}'),
        ]),
      ]),
    );
  }

  Widget _buildAmountSection() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: '0.00',
        prefixIcon: const Icon(Icons.attach_money, color: primaryBlue),
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
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Send Money', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}


