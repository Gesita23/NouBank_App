import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color primaryBlue = Color.fromARGB(255, 13, 71, 161);
const Color secondaryBlue = Color.fromARGB(255, 21, 101, 192);

class RequestMoneyPage extends StatefulWidget {
  const RequestMoneyPage({super.key});

  @override
  State<RequestMoneyPage> createState() => _RequestMoneyPageState();
}

class _RequestMoneyPageState extends State<RequestMoneyPage> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _selectedRecipient;
  String _searchType = 'username'; // 'username', 'phone', or 'email'
  
  // Account info from payment page
  String _accountType = 'Main Account';
  String _accountNumber = '****';
  double _currentBalance = 0.0;

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
    _reasonController.dispose();
    super.dispose();
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

        // Check if trying to request from self
        if (recipientData['uid'] == currentUser?.uid) {
          _showErrorDialog('You cannot request money from yourself');
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

  Future<void> _sendRequest() async {
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

    // Confirm request
    final confirmed = await _showConfirmDialog(amount);
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final timestamp = Timestamp.now();

      // Get requester's name
      final requesterDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final requesterName = requesterDoc.data()?['name'] ?? currentUser.email;
      final requesterUsername = requesterDoc.data()?['username'] ?? 'unknown';

      // Create payment request document
      await FirebaseFirestore.instance.collection('payment_requests').add({
        'requesterId': currentUser.uid,
        'requesterName': requesterName,
        'requesterUsername': requesterUsername,
        'requesterEmail': currentUser.email,
        'recipientId': _selectedRecipient!['uid'],
        'recipientName': _selectedRecipient!['name'],
        'recipientUsername': _selectedRecipient!['username'],
        'recipientEmail': _selectedRecipient!['email'],
        'amount': amount,
        'reason': _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
        'status': 'pending', // pending, accepted, rejected
        'createdAt': timestamp,
      });

      if (mounted) {
        _showSuccessDialog(amount);
      }
    } catch (e) {
      _showErrorDialog('Request failed: $e');
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
            title: const Text('Confirm Request'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Request \$${amount.toStringAsFixed(2)} from:'),
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
                if (_reasonController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Reason: ${_reasonController.text.trim()}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: primaryBlue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The recipient will receive a notification and can choose to accept or decline',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
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
                  'Send Request',
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
              'Request Sent!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Requesting \$${amount.toStringAsFixed(2)} from',
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'They will be notified and can accept or decline your request',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
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
          'Request Money',
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
                _buildInfoCard(),
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
                _buildReasonSection(),
                const SizedBox(height: 30),
                _buildRequestButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.request_page,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Request Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Send a payment request to anyone',
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
          const Text(
            'Request From',
            style: TextStyle(
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
            'Amount to Request',
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

  Widget _buildReasonSection() {
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
            'Reason (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'What is this request for? (e.g., Dinner split, Rent)',
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

  Widget _buildRequestButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendRequest,
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
                'Send Request',
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