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
  String _searchType = 'username'; // 'username', 'phone', or 'email'
  
  // Account info from payment page
  String _accountType = 'Main Account';
  String _accountNumber = '****';

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get account info from route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _accountType = args['accountType'] ?? 'Main Account';
      _accountNumber = args['accountNumber'] ?? '****';
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
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _currentBalance = (doc.data()?['account_balance'] ?? 0.0).toDouble();
        });
      }
    }
  }

  Future<void> _searchRecipient() async {
    final searchValue = _recipientController.text.trim().toLowerCase();
    if (searchValue.isEmpty) {
      _showErrorDialog('Please enter ${_searchType == 'username' ? 'username' : _searchType == 'phone' ? 'phone number' : 'email'}');
      return;
    }

    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance.collection('users');

      // Search based on selected type
      if (_searchType == 'username') {
        query = query.where('username', isEqualTo: searchValue);
      } else if (_searchType == 'phone') {
        query = query.where('phone', isEqualTo: searchValue);
      } else {
        query = query.where('email', isEqualTo: searchValue);
      }

      final querySnapshot = await query.limit(1).get();

      if (querySnapshot.docs.isEmpty) {
        _showErrorDialog('No user found with this ${_searchType}');
        setState(() => _selectedRecipient = null);
      } else {
        final recipientData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        final currentUser = FirebaseAuth.instance.currentUser;

        // Check if trying to send to self
        if (recipientData['uid'] == currentUser?.uid) {
          _showErrorDialog('You cannot send money to yourself');
          setState(() => _selectedRecipient = null);
        } else {
          setState(() {
            _selectedRecipient = {
              'uid': recipientData['uid'],
              'name': recipientData['name'],
              'email': recipientData['email'],
              'username': recipientData['username'],
              'phone': recipientData['phone'],
            };
          });
          _showSuccessSnackbar('Recipient found: ${recipientData['name']}');
        }
      }
    } catch (e) {
      _showErrorDialog('Error searching recipient: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMoney() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRecipient == null) {
      _showErrorDialog('Please search and select a recipient first');
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      _showErrorDialog('Please enter a valid amount');
      return;
    }

    if (amount > _currentBalance) {
      _showErrorDialog('Insufficient balance');
      return;
    }

    // Confirm transaction
    final confirmed = await _showConfirmDialog(amount);
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final batch = FirebaseFirestore.instance.batch();
      final timestamp = Timestamp.now();

      // Get sender's name
      final senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final senderName = senderDoc.data()?['name'] ?? currentUser.email;

      // Update sender's balance and expenses
      final senderRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      batch.update(senderRef, {
        'account_balance': FieldValue.increment(-amount),
        'expenses': FieldValue.increment(amount),
      });

      // Update recipient's balance and income
      final recipientRef = FirebaseFirestore.instance.collection('users').doc(_selectedRecipient!['uid']);
      batch.update(recipientRef, {
        'account_balance': FieldValue.increment(amount),
        'income': FieldValue.increment(amount),
      });

      // Create transaction for sender (debit)
      final senderTransactionRef = FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(senderTransactionRef, {
        'userId': currentUser.uid,
        'type': 'debit',
        'amount': amount,
        'description': 'Sent to ${_selectedRecipient!['name']}',
        'category': 'Transfer',
        'recipient': _selectedRecipient!['username'] ?? _selectedRecipient!['email'],
        'note': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        'timestamp': timestamp,
      });

      // Create transaction for recipient (credit)
      final recipientTransactionRef = FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(recipientTransactionRef, {
        'userId': _selectedRecipient!['uid'],
        'type': 'credit',
        'amount': amount,
        'description': 'Received from $senderName',
        'category': 'Transfer',
        'sender': currentUser.email,
        'note': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        'timestamp': timestamp,
      });

      await batch.commit();

      if (mounted) {
        _showSuccessDialog(amount);
      }
    } catch (e) {
      _showErrorDialog('Transaction failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showConfirmDialog(double amount) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Confirm Transfer'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Send \$${amount.toStringAsFixed(2)} to:'),
                const SizedBox(height: 8),
                Text(
                  _selectedRecipient!['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '@${_selectedRecipient!['username']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (_noteController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Note: ${_noteController.text.trim()}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: Colors.white),
                ),
              ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Transfer Successful!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '\$${amount.toStringAsFixed(2)} sent to',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
              ),
            ),
            Text(
              _selectedRecipient!['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to payments
            },
            child: const Text(
              'Done',
              style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Send Money',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        elevation: 0,
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

  // STANDARDIZED HEADER - LOCKED TO ACCOUNT (NO DROPDOWN)
  Widget _buildAccountHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBlue, secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paying from',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _accountType,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _accountNumber,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Balance',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                ),
              ),
              Text(
                '\$${_currentBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSearchTypeButton('Username', 'username', Icons.alternate_email),
          ),
          Expanded(
            child: _buildSearchTypeButton('Phone', 'phone', Icons.phone),
          ),
          Expanded(
            child: _buildSearchTypeButton('Email', 'email', Icons.email),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTypeButton(String label, String value, IconData icon) {
    final isSelected = _searchType == value;
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
          color: isSelected ? primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientSection() {
    String hintText;
    TextInputType keyboardType;

    switch (_searchType) {
      case 'username':
        hintText = 'Enter username (e.g., @john_doe)';
        keyboardType = TextInputType.text;
        break;
      case 'phone':
        hintText = 'Enter phone number';
        keyboardType = TextInputType.phone;
        break;
      default:
        hintText = 'Enter email address';
        keyboardType = TextInputType.emailAddress;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Recipient',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _recipientController,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(
                _searchType == 'username'
                    ? Icons.alternate_email
                    : _searchType == 'phone'
                        ? Icons.phone
                        : Icons.email_outlined,
                color: primaryBlue,
              ),
              suffixIcon: IconButton(
                onPressed: _isLoading ? null : _searchRecipient,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryBlue,
                        ),
                      )
                    : const Icon(Icons.search, color: primaryBlue),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryBlue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter ${_searchType}';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedRecipient!['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '@${_selectedRecipient!['username']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                if (_searchType == 'phone')
                  Text(
                    _selectedRecipient!['phone'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixIcon: const Icon(Icons.attach_money, color: primaryBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryBlue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter amount';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid amount';
              }
              if (amount > _currentBalance) {
                return 'Insufficient balance';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [10, 20, 50, 100].map((amount) {
              return ActionChip(
                label: Text('\$$amount'),
                onPressed: () {
                  _amountController.text = amount.toString();
                },
                backgroundColor: Colors.grey[100],
                labelStyle: const TextStyle(color: primaryBlue),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Note (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add a note for this transaction',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryBlue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendMoney,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Send Money',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}