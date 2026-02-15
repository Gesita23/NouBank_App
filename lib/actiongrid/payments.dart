import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../bottom_nav.dart';

Color primaryBlue = Color.fromARGB(255, 13, 71, 161);
Color secondaryBlue = Color.fromARGB(255, 21, 101, 192);

// Payment Option Model
class PaymentOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}

// Account Model for dropdown
class BankAccount {
  final String accountType;
  final String accountNumber;
  final double balance;
  final IconData icon;
  final Color color;

  BankAccount({
    required this.accountType,
    required this.accountNumber,
    required this.balance,
    required this.icon,
    required this.color,
  });
}

class PaymentsPage extends StatefulWidget {
  final String? accountType;
  final double? accountBalance;
  final String? accountNumber;

  PaymentsPage({
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
  int _selectedIndex = 1;

  // Currently selected account
  late BankAccount selectedAccount;
  List<BankAccount> availableAccounts = [];

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
        final data = doc.data();
        final balance = (data?['account_balance'] ?? 0.0).toDouble();

        setState(() {
          userName = data?['name'] ?? 'User';
          totalBalance = balance;

          // UPDATED: Create available accounts (Savings is primary with full balance)
          availableAccounts = [
            BankAccount(
              accountType: 'Savings Account',
              accountNumber: '****5678',
              balance: balance, // Primary account gets full balance
              icon: Icons.savings,
              color: primaryBlue,
            ),
            BankAccount(
              accountType: 'Checking Account',
              accountNumber: '****1234',
              balance: balance * 0.3, // Secondary account
              icon: Icons.account_balance_wallet,
              color: Colors.green,
            ),
          ];

          // UPDATED: Set selected account based on passed arguments or default to Savings
          if (widget.accountType != null) {
            // Find matching account from arguments
            try {
              selectedAccount = availableAccounts.firstWhere(
                (acc) => acc.accountType == widget.accountType,
                orElse: () => availableAccounts[0], // Default to Savings
              );
            } catch (e) {
              selectedAccount = availableAccounts[0]; // Default to Savings
            }
          } else {
            // Default to Savings Account (index 0)
            selectedAccount = availableAccounts[0];
          }
        });
      }
    }
  }

  void _onItemTapped(int index) {
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

  // Show account selector bottom sheet
  void _showAccountSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Title
            Text(
              'Select Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),

            // Account list
            ...availableAccounts.map((account) => _buildAccountSelectorItem(account)),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSelectorItem(BankAccount account) {
    final isSelected = selectedAccount.accountType == account.accountType;

    return InkWell(
      onTap: () {
        setState(() {
          selectedAccount = account;
        });
        Navigator.pop(context); // Close bottom sheet
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryBlue : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [account.color, account.color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: account.color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                account.icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 16),

            // Account info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.accountType,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? primaryBlue : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    account.accountNumber,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Balance and checkmark
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs ${account.balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? primaryBlue : Colors.black87,
                  ),
                ),
                if (isSelected) ...[
                  SizedBox(height: 4),
                  Icon(
                    Icons.check_circle,
                    color: primaryBlue,
                    size: 20,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  final List<PaymentOption> paymentOptions = [
    PaymentOption(
      icon: Icons.person_outline,
      title: 'Send to Contact',
      subtitle: 'Transfer to NouBank users',
      route: '/send_to_contact',
    ),
    PaymentOption(
      icon: Icons.qr_code_scanner,
      title: 'Scan QR Code',
      subtitle: 'Pay by scanning QR',
      route: '/scan',
    ),
    PaymentOption(
      icon: Icons.receipt_long,
      title: 'Pay Bills',
      subtitle: 'Electricity, water, internet',
      route: '/pay_bills',
    ),
    PaymentOption(
      icon: Icons.request_page,
      title: 'Request Money',
      subtitle: 'Request from others',
      route: '/request_money',
    ),
    PaymentOption(
      icon: Icons.account_balance,
      title: 'Bank Transfer',
      subtitle: 'Transfer to other banks',
      route: '/bank_transfer',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Get arguments if passed from route
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    // Update selected account if arguments were passed via route
    if (args != null && availableAccounts.isNotEmpty) {
      final accountType = args['accountType'] as String?;
      if (accountType != null) {
        try {
          final matchingAccount = availableAccounts.firstWhere(
            (acc) => acc.accountType == accountType,
            orElse: () => availableAccounts[0],
          );
          if (selectedAccount.accountType != matchingAccount.accountType) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                selectedAccount = matchingAccount;
              });
            });
          }
        } catch (e) {
          // Keep current selection
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Make Payment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: availableAccounts.isEmpty
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHybridAccountHeader(),
                  SizedBox(height: 20),
                  _buildQuickActions(),
                  SizedBox(height: 24),
                  _buildPaymentOptions(),
                  SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildHybridAccountHeader() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: EdgeInsets.all(20),
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
      child: Stack(
        children: [
          // Decorative circle
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
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            selectedAccount.icon,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            selectedAccount.accountType,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        selectedAccount.accountNumber,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),

                  // UPDATED: Change account button with dropdown functionality
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton.icon(
                      onPressed: _showAccountSelector,
                      icon: Icon(Icons.swap_horiz, size: 18, color: primaryBlue),
                      label: Text(
                        'Change',
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Divider(height: 1, color: Colors.white.withOpacity(0.2)),
              SizedBox(height: 16),
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
                    'Rs ${selectedAccount.balance.toStringAsFixed(2)}',
                    style: TextStyle(
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

  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionButton(
                icon: Icons.send,
                label: 'Send',
                onTap: () => Navigator.pushNamed(context, '/send_to_contact'),
              ),
              _buildQuickActionButton(
                icon: Icons.qr_code_scanner,
                label: 'Scan',
                onTap: () => Navigator.pushNamed(context, '/scan'),
              ),
              _buildQuickActionButton(
                icon: Icons.request_page,
                label: 'Request',
                onTap: () => Navigator.pushNamed(context, '/request_money'),
              ),
              _buildQuickActionButton(
                icon: Icons.receipt_long,
                label: 'Bills',
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 70,
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: primaryBlue,
                size: 26,
              ),
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Payment Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemCount: paymentOptions.length,
            itemBuilder: (context, index) {
              return _buildPaymentOptionCard(paymentOptions[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionCard(PaymentOption option) {
    return InkWell(
      onTap: () {
        if (option.route == '/scan' ||
            option.route == '/send_to_contact' ||
            option.route == '/pay_bills' ||
            option.route == '/request_money' ||
            option.route == '/bank_transfer') {
          // UPDATED: Pass current selected account info
          Navigator.pushNamed(
            context,
            option.route,
            arguments: {
              'accountType': selectedAccount.accountType,
              'accountBalance': selectedAccount.balance,
              'accountNumber': selectedAccount.accountNumber,
            },
          );
        } else {
          _showComingSoonDialog(option.title);
        }
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              option.icon,
              color: primaryBlue,
              size: 30,
            ),
            SizedBox(height: 10),
            Text(
              option.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 3),
            Text(
              option.subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
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
          children: [
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
            child: Text(
              'OK',
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}