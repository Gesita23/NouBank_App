import 'package:flutter/material.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

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
      bottomNavigationBar: _buildBottomNav(context),
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

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 4, // More tab selected
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        // Handle navigation between tabs
        switch (index) {
          case 0:
            // Navigate to Home
            break;
          case 1:
            // Navigate to Accounts
            break;
          case 2:
            // Navigate to Transact
            break;
          case 3:
            // Navigate to Cards
            break;
          case 4:
            // Already on More page
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          activeIcon: Icon(Icons.account_balance_wallet),
          label: "Accounts",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.swap_horiz),
          activeIcon: Icon(Icons.swap_horiz),
          label: "Transact",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.credit_card_outlined),
          activeIcon: Icon(Icons.credit_card),
          label: "Cards",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          activeIcon: Icon(Icons.more_horiz),
          label: "More",
        ),
      ],
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
                Navigator.pop(context);
                // Perform logout action
                _performLogout(context);
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

  void _performLogout(BuildContext context) {
    // Clear user session
    // Navigate to login page
    // Example:
    // Navigator.pushAndRemoveUntil(
    //   context,
    //   MaterialPageRoute(builder: (context) => LoginPage()),
    //   (route) => false,
    // );
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
      appBar: AppBar(
        title: const Text("Invest"),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text("Invest Page - Coming Soon"),
      ),
    );
  }
}

class StatementsPage extends StatelessWidget {
  const StatementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Statements & Advices"),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text("Statements & Advices Page - Coming Soon"),
      ),
    );
  }
}

class PersonalDetailsPage extends StatelessWidget {
  const PersonalDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal Details"),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text("Personal Details Page - Coming Soon"),
      ),
    );
  }
}

class StandingOrdersPage extends StatelessWidget {
  const StandingOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Standing Orders"),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text("Standing Orders Page - Coming Soon"),
      ),
    );
  }
}

class BeneficiariesPage extends StatelessWidget {
  const BeneficiariesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Beneficiaries"),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text("Beneficiaries Page - Coming Soon"),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text("Settings Page - Coming Soon"),
      ),
    );
  }
}

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Us"),
        backgroundColor: Colors.deepPurple,
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
              "+1 (800) 123-4567",
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              Icons.email,
              "Email",
              "support@edbank.com",
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
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.deepPurple,
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

