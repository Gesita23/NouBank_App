import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bottom_nav.dart';
import 'actiongrid/qr_scan.dart';
import 'actiongrid/payments.dart';
import 'actiongrid/statistics.dart';
import 'actiongrid/other.dart';


// DESIGN CONSTANTS
const Color primarypurple = Color.fromARGB(255, 13, 71, 161);
const Color secondarypurple = Color.fromARGB(255, 21, 101, 192);

// ACTION GRID MODEL
class ActionItem {
  final IconData icon;
  final String label;
  final Color iconColor;
  final String route;

  const ActionItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.route,
  });
}

const List<ActionItem> actionItems = [
  ActionItem(
    icon: Icons.qr_code_scanner,
    label: 'Scan to Pay',
    iconColor: primarypurple,
    route:'/scan',
  ),
  ActionItem(
    icon: Icons.wallet_outlined,
    label: 'Payments',
    iconColor: primarypurple,
    route:'/payments',
  ),
  ActionItem(
    icon: Icons.bar_chart_outlined,
    label: 'Statistics',
    iconColor: primarypurple,
    route:'/statistics',
  ),
  ActionItem(
    icon: Icons.apps, 
    label: 'Other',
    iconColor: primarypurple,
    route:'/other',
   ),
];

/// navbar
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    //Handle navigation to different pages
    switch (index) {
      case 0: //Already on Home, just update selected index
        setState(() {
          _selectedIndex = index;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: const HomePageContent(),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

/// content
class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primarypurple),
          );
        }

        final data = snapshot.data ?? {};
        final name = data['name'] ?? 'User';
        final balance = (data['account_balance'] ?? 0).toString();
        final income = (data['income'] ?? 0).toString();
        final expenses = (data['expenses'] ?? 0).toString();

        return SingleChildScrollView(
          child: Column(
            children: [
              HeaderSection(
                name: name,
                balance: balance,
                income: income,
                expenses: expenses,
              ),
              const ActionGridSection(),
              const TransactionHistorySection(),
            ],
          ),
        );
      },
    );
  }
}

/// header
class HeaderSection extends StatelessWidget {
  final String name;
  final String balance;
  final String income;
  final String expenses;

  const HeaderSection({
    super.key,
    required this.name,
    required this.balance,
    required this.income,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2575CF), Color(0xFF264779)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_topBar(), const SizedBox(height: 20), _greeting()],
            ),
          ),
          Positioned(top: 140, left: 20, right: 20, child: _balanceCard()),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          'NouBank',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Icon(Icons.notifications_none, color: Colors.white),
      ],
    );
  }

  Widget _greeting() {
    return Row(
      children: [
        const Icon(Icons.lock_outline, color: Colors.white),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome!', style: TextStyle(color: Colors.white70)),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _balanceCard() {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primarypurple,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Balance', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            '\$$balance',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BalanceMiniItem(
                icon: Icons.arrow_downward,
                label: 'Income',
                amount: '\$$income',
              ),
              BalanceMiniItem(
                icon: Icons.arrow_upward,
                label: 'Expenses',
                amount: '\$$expenses',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// income/exp
class IncomeExpenseSummary extends StatelessWidget {
  final String income;
  final String expenses;

  const IncomeExpenseSummary({
    super.key,
    required this.income,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _item(Icons.arrow_downward, 'Income', income, Colors.green),
          _item(Icons.arrow_upward, 'Expenses', expenses, Colors.red),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, String amount, Color color) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            Text(
              '\$$amount',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

class BalanceMiniItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;

  const BalanceMiniItem({
    super.key,
    required this.icon,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(amount, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ],
    );
  }
}

// Action Grid Section
class ActionGridSection extends StatelessWidget {
  const ActionGridSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What would you like to do today',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 15),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.8,
              children: actionItems
                  .map((item) => ActionButton(item: item))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

//individual actionbutton in the grid
class ActionButton extends StatelessWidget {
  final ActionItem item;

  const ActionButton({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, item.route);
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
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: item.iconColor, size: 30),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//Transaction History Section
class TransactionHistorySection extends StatelessWidget {
  const TransactionHistorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            _buildSectionHeader(),
            const SizedBox(height: 10),
            Column(
              children: List.generate(5, (index) => const TransactionRow()),
            ),
          ],
        ),
      ),
    );
  }
}

//Section header with See All button
Widget _buildSectionHeader() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Transaction History',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      TextButton(
        onPressed: () {},
        child: const Text(
          'See All',
          style: TextStyle(
            fontSize: 16,
            color: primarypurple,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

//Single Transaction Row with skeleton loading effect
class TransactionRow extends StatelessWidget {
  const TransactionRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _buildIconPlaceholder(),
          const SizedBox(width: 15),
          _buildDetailsPlaceholder(),
          const SkeletonContainer(width: 70, height: 16, radius: 4),
        ],
      ),
    );
  }
}

//Transaction Icon placeholder
Widget _buildIconPlaceholder() {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 1,
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: const SkeletonContainer(width: 24, height: 24, radius: 4),
  );
}

//Transaction History Placheolder
Widget _buildDetailsPlaceholder() {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonContainer(width: 120, height: 16, radius: 4),
        SizedBox(height: 5),
        SkeletonContainer(width: 80, height: 14, radius: 4),
      ],
    ),
  );
}

//Utility Widget
class SkeletonContainer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonContainer({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
