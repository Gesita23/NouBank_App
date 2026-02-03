import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bottom_nav.dart';

// Color constants matching your theme
const Color primaryBlue = Color.fromARGB(255, 13, 71, 161);
const Color secondaryBlue = Color.fromARGB(255, 21, 101, 192);

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  int _selectedIndex = 4;

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
        Navigator.pushNamed(context, '/cards');
        break;
      case 4:
        // Already on More page
        setState(() {
          _selectedIndex = index;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "More",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Financial Services Section
              _buildMenuCard([
                _MenuItem(
                  icon: Icons.trending_up,
                  label: "Invest",
                  onTap: () => _navigateToInvest(context),
                ),
                _MenuItem(
                  icon: Icons.article_outlined,
                  label: "Statements & Advices",
                  onTap: () => _navigateToStatements(context),
                ),
              ]),
              
              const SizedBox(height: 16),
              
              // Account Management Section
              _buildMenuCard([
                _MenuItem(
                  icon: Icons.person_outline,
                  label: "Personal details",
                  onTap: () => _navigateToPersonalDetails(context),
                ),
                _MenuItem(
                  icon: Icons.autorenew,
                  label: "Standing orders",
                  onTap: () => _navigateToStandingOrders(context),
                ),
                _MenuItem(
                  icon: Icons.people_outline,
                  label: "Beneficiaries",
                  onTap: () => _navigateToBeneficiaries(context),
                ),
                _MenuItem(
                  icon: Icons.settings_outlined,
                  label: "Settings",
                  onTap: () => _navigateToSettings(context),
                ),
              ]),
              
              const SizedBox(height: 16),
              
              // Support & Logout Section
              _buildMenuCard([
                _MenuItem(
                  icon: Icons.phone_outlined,
                  label: "Contact us",
                  onTap: () => _navigateToContact(context),
                ),
                _MenuItem(
                  icon: Icons.logout,
                  label: "Log out",
                  textColor: Colors.red,
                  iconBackgroundColor: Colors.red,
                  onTap: () => _showLogoutDialog(context),
                ),
              ]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.map((item) {
          final isLast = items.indexOf(item) == items.length - 1;
          return Column(
            children: [
              _buildMenuItem(item),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 76,
                  color: Colors.grey[200],
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.iconBackgroundColor?.withOpacity(0.1) ?? 
                       Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: item.iconBackgroundColor ?? Colors.black87,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: item.textColor ?? Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // Navigation Methods
  void _navigateToInvest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InvestPage()),
    );
  }

  void _navigateToStatements(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatementsPage()),
    );
  }

  void _navigateToPersonalDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PersonalDetailsPage()),
    );
  }

  void _navigateToStandingOrders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StandingOrdersPage()),
    );
  }

  void _navigateToBeneficiaries(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BeneficiariesPage()),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  void _navigateToContact(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ContactUsPage()),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Log out"),
          content: const Text("Are you sure you want to log out?"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _performLogout(context); // Perform logout
              },
              child: const Text(
                "Log out",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLogout(BuildContext context) async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      // Navigate to auth screen and clear navigation stack
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      // Show error if logout fails
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Menu Item Model
class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconBackgroundColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor,
    this.iconBackgroundColor,
  });
}

// Placeholder pages for navigation
class InvestPage extends StatelessWidget {
  const InvestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Invest", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Investment Options",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Grow your wealth with our investment products",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            _buildInvestmentCard(
              "Fixed Deposit",
              "Earn guaranteed returns with low risk",
              "4.5% p.a.",
              Icons.account_balance,
              Colors.green,
            ),
            const SizedBox(height: 12),
            
            _buildInvestmentCard(
              "Mutual Funds",
              "Diversified portfolio managed by experts",
              "8-12% p.a.",
              Icons.trending_up,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            
            _buildInvestmentCard(
              "Stocks & Shares",
              "Invest in individual companies",
              "Variable",
              Icons.show_chart,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            
            _buildInvestmentCard(
              "Government Bonds",
              "Secure investment backed by government",
              "3.8% p.a.",
              Icons.security,
              Colors.purple,
            ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Investment products will be available soon. Contact us to learn more.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentCard(String title, String description, String returns, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              returns,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatementsPage extends StatelessWidget {
  const StatementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Statements & Advices", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Account Statements",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Download your monthly statements and tax documents",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            _buildStatementCard(
              "January 2026",
              "Account Statement",
              "Generated on Jan 31, 2026",
              Icons.picture_as_pdf,
            ),
            const SizedBox(height: 12),
            
            _buildStatementCard(
              "December 2025",
              "Account Statement",
              "Generated on Dec 31, 2025",
              Icons.picture_as_pdf,
            ),
            const SizedBox(height: 12),
            
            _buildStatementCard(
              "November 2025",
              "Account Statement",
              "Generated on Nov 30, 2025",
              Icons.picture_as_pdf,
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              "Tax Documents",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildStatementCard(
              "Tax Year 2025",
              "Annual Tax Statement",
              "Generated on Jan 15, 2026",
              Icons.receipt_long,
            ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue.withOpacity(0.1), secondaryBlue.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryBlue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.mail_outline, color: primaryBlue, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    "Email Statements",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Get your statements delivered to ${user?.email ?? 'your email'}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Enable email statements
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Enable Email Statements",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatementCard(String title, String type, String date, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.red, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Download statement
            },
            icon: const Icon(Icons.download, color: primaryBlue),
          ),
        ],
      ),
    );
  }
}

class PersonalDetailsPage extends StatelessWidget {
  const PersonalDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Personal Details"),
          backgroundColor: primaryBlue,
        ),
        body: const Center(
          child: Text('Please log in to view your details'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Personal Details",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryBlue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? 'User';
          final email = data['email'] ?? user.email ?? 'N/A';
          final phone = data['phone'] ?? 'N/A';
          final username = data['username'] ?? 'N/A';
          final balance = (data['account_balance'] ?? 0).toString();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: primaryBlue,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@$username',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Personal Information Section
                  const Text(
                    "Personal Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoCard([
                    _InfoItem(
                      icon: Icons.person_outline,
                      label: "Full Name",
                      value: name,
                    ),
                    _InfoItem(
                      icon: Icons.alternate_email,
                      label: "Username",
                      value: '@$username',
                    ),
                    _InfoItem(
                      icon: Icons.email_outlined,
                      label: "Email",
                      value: email,
                    ),
                    _InfoItem(
                      icon: Icons.phone_outlined,
                      label: "Phone",
                      value: phone,
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Account Information Section
                  const Text(
                    "Account Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoCard([
                    _InfoItem(
                      icon: Icons.account_balance_outlined,
                      label: "Account Balance",
                      value: "\$$balance",
                    ),
                    _InfoItem(
                      icon: Icons.fingerprint,
                      label: "User ID",
                      value: user.uid.substring(0, 20) + '...',
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Edit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to edit page or show edit dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit profile feature coming soon!'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Edit Profile",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.map((item) {
          final isLast = items.indexOf(item) == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        color: primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.value,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 62,
                  color: Colors.grey[200],
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class StandingOrdersPage extends StatelessWidget {
  const StandingOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Standing Orders", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Active Standing Orders",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Manage your recurring payments",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            _buildStandingOrderCard(
              "Rent Payment",
              "John Doe",
              "\$1,200.00",
              "Monthly - 1st of every month",
              Icons.home,
              Colors.blue,
              true,
            ),
            const SizedBox(height: 12),
            
            _buildStandingOrderCard(
              "Electricity Bill",
              "Utility Company",
              "\$150.00",
              "Monthly - 15th of every month",
              Icons.electrical_services,
              Colors.orange,
              true,
            ),
            const SizedBox(height: 12),
            
            _buildStandingOrderCard(
              "Internet Subscription",
              "ISP Provider",
              "\$80.00",
              "Monthly - 5th of every month",
              Icons.wifi,
              Colors.purple,
              true,
            ),
            const SizedBox(height: 12),
            
            _buildStandingOrderCard(
              "Gym Membership",
              "Fitness Center",
              "\$60.00",
              "Monthly - 10th of every month",
              Icons.fitness_center,
              Colors.green,
              false,
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Add new standing order
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Add New Standing Order",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Standing orders are automatically processed on the scheduled date. Ensure sufficient balance.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandingOrderCard(
    String title,
    String recipient,
    String amount,
    String frequency,
    IconData icon,
    Color color,
    bool isActive,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "To: $recipient",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? "Active" : "Paused",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                frequency,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BeneficiariesPage extends StatelessWidget {
  const BeneficiariesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Beneficiaries", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Saved Beneficiaries",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Quick access to your frequent recipients",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            _buildBeneficiaryCard(
              "John Doe",
              "john.doe@email.com",
              "Personal",
              Colors.blue,
            ),
            const SizedBox(height: 12),
            
            _buildBeneficiaryCard(
              "Sarah Smith",
              "54123456",
              "Mobile",
              Colors.green,
            ),
            const SizedBox(height: 12),
            
            _buildBeneficiaryCard(
              "ABC Company Ltd",
              "Account: 123456789",
              "Business",
              Colors.orange,
            ),
            const SizedBox(height: 12),
            
            _buildBeneficiaryCard(
              "Mom",
              "55987654",
              "Family",
              Colors.pink,
            ),
            const SizedBox(height: 12),
            
            _buildBeneficiaryCard(
              "Utility Services",
              "utilities@service.com",
              "Bills",
              Colors.purple,
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showAddBeneficiaryDialog(context);
                },
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: const Text(
                  "Add New Beneficiary",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Save beneficiaries for faster and easier payments.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeneficiaryCard(
    String name,
    String details,
    String category,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.1),
            child: Text(
              name[0].toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddBeneficiaryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Add Beneficiary"),
          content: const Text(
            "This feature will allow you to add new beneficiaries for quick payments.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _darkModeEnabled = false;
  bool _marketingEmails = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "App Settings",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Customize your banking experience",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Security Section
            const Text(
              "Security",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildSettingsCard([
              _buildSettingTile(
                "Biometric Login",
                "Use fingerprint or face recognition",
                Icons.fingerprint,
                Switch(
                  value: _biometricEnabled,
                  onChanged: (value) {
                    setState(() {
                      _biometricEnabled = value;
                    });
                  },
                  activeColor: primaryBlue,
                ),
              ),
              _buildSettingTile(
                "Change Password",
                "Update your account password",
                Icons.lock_outline,
                Icon(Icons.chevron_right, color: Colors.grey[400]),
                onTap: () {
                  // Navigate to change password
                },
              ),
              _buildSettingTile(
                "Two-Factor Authentication",
                "Add extra security to your account",
                Icons.security,
                Icon(Icons.chevron_right, color: Colors.grey[400]),
                onTap: () {
                  // Navigate to 2FA setup
                },
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // Notifications Section
            const Text(
              "Notifications",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildSettingsCard([
              _buildSettingTile(
                "Push Notifications",
                "Receive alerts for transactions",
                Icons.notifications_outlined,
                Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                  activeColor: primaryBlue,
                ),
              ),
              _buildSettingTile(
                "Marketing Emails",
                "Receive offers and promotions",
                Icons.email_outlined,
                Switch(
                  value: _marketingEmails,
                  onChanged: (value) {
                    setState(() {
                      _marketingEmails = value;
                    });
                  },
                  activeColor: primaryBlue,
                ),
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // Appearance Section
            const Text(
              "Appearance",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildSettingsCard([
              _buildSettingTile(
                "Dark Mode",
                "Switch to dark theme",
                Icons.dark_mode_outlined,
                Switch(
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                  },
                  activeColor: primaryBlue,
                ),
              ),
              _buildSettingTile(
                "Language",
                "English (US)",
                Icons.language,
                Icon(Icons.chevron_right, color: Colors.grey[400]),
                onTap: () {
                  // Navigate to language selection
                },
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // About Section
            const Text(
              "About",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildSettingsCard([
              _buildSettingTile(
                "Privacy Policy",
                "Read our privacy policy",
                Icons.privacy_tip_outlined,
                Icon(Icons.chevron_right, color: Colors.grey[400]),
                onTap: () {
                  // Navigate to privacy policy
                },
              ),
              _buildSettingTile(
                "Terms & Conditions",
                "View terms of service",
                Icons.description_outlined,
                Icon(Icons.chevron_right, color: Colors.grey[400]),
                onTap: () {
                  // Navigate to terms
                },
              ),
              _buildSettingTile(
                "App Version",
                "1.0.0",
                Icons.info_outline,
                const SizedBox(),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon,
    Widget trailing, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryBlue, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Contact Us", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Get in Touch",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildContactItem(
              Icons.phone,
              "Phone",
              "+230 5XXX XXXX",
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              Icons.email,
              "Email",
              "nouBank@gmail.com",
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              Icons.chat_bubble_outline,
              "Live Chat",
              "Available 24/7",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

