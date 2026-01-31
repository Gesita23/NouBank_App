import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bottom_nav.dart';

const Color primaryBlue = Color.fromARGB(255, 13, 71, 161);
const Color secondaryBlue = Color.fromARGB(255, 21, 101, 192);

// Payment Option Model
class PaymentOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;

  const PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });
}

class PaymentsPage extends StatefulWidget {
  // Optional parameters to receive account info from account page
  final String? accountType; // e.g., "Checking", "Savings", "Credit Card"
  final double? accountBalance;
  final String? accountNumber; // e.g., "****1234"
  
  const PaymentsPage({
    super.key,
    this.accountType,
    this.accountBalance,
    this.accountNumber,
  });

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  String userName = '';
  double totalBalance = 0.0;
  int _selectedIndex = 1; // Default to index 1 since this could be accessed from Account

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          userName = doc.data()?['name'] ?? 'User';
          totalBalance = (doc.data()?['account_balance'] ?? 0.0).toDouble();
        });
      }
    }
  }

  void _onItemTapped(int index) {
    // Handle navigation
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 1:
        Navigator.pushNamed(context, '/account');
        break;
      case 2:
        Navigator.pushNamed(context, '/transactions');
        break;
      case 3:
        Navigator.pushNamed(context, '/carts');
        break;
      case 4:
        Navigator.pushNamed(context, '/more');
        break;
    }
  }

  // Payment options list
  final List<PaymentOption> paymentOptions = const [
    PaymentOption(
      icon: Icons.person_outline,
      title: 'Send to Contact',
      subtitle: 'Transfer to NouBank users',
      color: Color(0xFF4CAF50),
      route: '/send_to_contact',
    ),
    PaymentOption(
      icon: Icons.qr_code_scanner,
      title: 'Scan QR Code',
      subtitle: 'Pay by scanning QR',
      color: Color(0xFF2196F3),
      route: '/scan',
    ),
    PaymentOption(
      icon: Icons.receipt_long,
      title: 'Pay Bills',
      subtitle: 'Electricity, water, internet',
      color: Color(0xFFFF9800),
      route: '/pay_bills',
    ),
    PaymentOption(
      icon: Icons.request_page,
      title: 'Request Money',
      subtitle: 'Request from others',
      color: Color(0xFFE91E63),
      route: '/request_money',
    ),
    PaymentOption(
      icon: Icons.account_balance,
      title: 'Bank Transfer',
      subtitle: 'Transfer to other banks',
      color: Color(0xFF00BCD4),
      route: '/bank_transfer',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Make Payment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHybridAccountHeader(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildPaymentOptions(),
            const SizedBox(height: 80), // Extra padding for navbar
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // ============================================
  // HYBRID HEADER: Option 1 layout + Option 2 visual appeal
  // ============================================
  Widget _buildHybridAccountHeader() {
    // Use passed account info if available, otherwise use defaults
    final accountType = widget.accountType ?? 'Main Account';
    final balance = widget.accountBalance ?? totalBalance;
    final accountNum = widget.accountNumber ?? '****';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
      child: Stack(
        children: [
          // Decorative circle (subtle, top-right)
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                        accountType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        accountNum,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  // Change account button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        // Navigate back to account selection or show account picker
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.swap_horiz, size: 18, color: primaryBlue),
                      label: const Text(
                        'Change',
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
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
                    '\$${balance.toStringAsFixed(2)}',
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
        ],
      ),
    );
  }

  // Quick Actions (Most used actions)
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionButton(
                icon: Icons.send,
                label: 'Send',
                color: const Color(0xFF4CAF50),
                onTap: () => Navigator.pushNamed(context, '/send_to_contact'),
              ),
              _buildQuickActionButton(
                icon: Icons.qr_code_scanner,
                label: 'Scan',
                color: const Color(0xFF2196F3),
                onTap: () => Navigator.pushNamed(context, '/scan'),
              ),
              _buildQuickActionButton(
                icon: Icons.request_page,
                label: 'Request',
                color: const Color(0xFFE91E63),
                onTap: () => Navigator.pushNamed(context, '/request_money'),
              ),
              _buildQuickActionButton(
                icon: Icons.receipt_long,
                label: 'Bills',
                color: const Color(0xFFFF9800),
                onTap: () => Navigator.pushNamed(context, '/pay_bills'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // All Payment Options
  Widget _buildPaymentOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Payment Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...paymentOptions.map((option) => _buildPaymentOptionCard(option)),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionCard(PaymentOption option) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            // Navigate to implemented features, show coming soon for others
            if (option.route == '/scan' || 
                option.route == '/send_to_contact' ||
                option.route == '/pay_bills' ||
                option.route == '/request_money' ||
                option.route == '/bank_transfer') {
              Navigator.pushNamed(context, option.route);
            } else {
              _showComingSoonDialog(option.title);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: option.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    option.icon,
                    color: option.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: primaryBlue),
            SizedBox(width: 10),
            Text('Coming Soon'),
          ],
        ),
        content: Text(
          '$feature feature is under development and will be available soon!',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}