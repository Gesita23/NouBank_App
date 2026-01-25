import 'package:flutter/material.dart';


///Design Constants///
const Color primarypurple = Color.fromARGB(255, 13, 71, 161);
const Color secondarypurple = Color.fromARGB(255, 21, 101, 192);

//Data model for action grid buttons
class ActionItem {
  final IconData icon;
  final String label;
  final Color iconColor;

  const ActionItem({
    required this.icon,
    required this.label,
    required this.iconColor,
  });
}

//List of action items displayed in the grid
const List<ActionItem> actionItems = [
  ActionItem(
    icon: Icons.qr_code_scanner,
    label: 'Scan to Pay',
    iconColor: primarypurple,
  ),
  ActionItem(
    icon: Icons.wallet_outlined,
    label: 'Payments',
    iconColor: primarypurple,
  ),
  ActionItem(
    icon: Icons.shopping_cart_checkout_outlined,
    label: 'Shop',
    iconColor: primarypurple,
  ),
  ActionItem(icon: Icons.apps, label: 'Other', iconColor: primarypurple),
];

//Homepage
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
    print("Navigation Item Tapped:Index $index");
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

      bottomNavigationBar: _buildBottomNavigationBar(),
      /* floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,*/
    );
  }

  //Bottom navigator bar
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        color: Colors.white,
        elevation: 0,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.account_balance_wallet, 'Account', 1),
              _buildNavItem(Icons.compare_arrows, 'Transact', 2),
              _buildNavItem(Icons.credit_card, 'Cards', 3),
              _buildNavItem(Icons.more_horiz, 'More', 4),
            ],
          ),
        ),
      ),
    );
  }

  //Build Individual navigation items
  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? primarypurple : Colors.grey;

    return InkWell(
      onTap: () => onItemTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Floating Action Button
  /*Widget _buildFloatingActionButton() {
    return Container(
      width: 65,
      height:65,
      decoration:BoxDecoration(
        shape:BoxShape.circle,
        gradient:const LinearGradient(colors: [primarypurple,secondarypurple],
         begin:Alignment.topLeft,
         end:Alignment.bottomRight),
         boxShadow:[
          BoxShadow(
            color:secondarypurple,
            blurRadius:10,
            offset: const Offset(0, 4),
          )
         ]
      ),
      child:FloatingActionButton(onPressed : () => onItemTapped(2),
      backgroundColor: Colors.transparent,
      elevation:0,
      child: const Icon(
        Icons.qr_code_scanner,
        color:Colors.white,
        size:28,
      ),
      
      
      ),
    );
  }*/
} //endclass

//PAGE CONTENT LAYOUT//
class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderSection(),
          ActionGridSection(),
          TransactionHistorySection(),
        ],
      ),
    );
  }
}

//Header Section
class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 37, 117, 207),
                  Color.fromARGB(255, 38, 71, 121),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // greeting
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 20),
                _buildGreeting(),
              ],
            ),
          ),

          // Floating Balance Card
          Positioned(top: 140, left: 20, right: 20, child: _buildBalanceCard()),
        ],
      ),
    );
  }

  // Top App Bar
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'NouBank',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            _buildCircleIcon(Icons.chat_bubble_outline),
            const SizedBox(width: 8),
            _buildCircleIcon(Icons.notifications_none),
          ],
        ),
      ],
    );
  }

  // Circle Icon Button
  Widget _buildCircleIcon(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.25),
      ),
      padding: const EdgeInsets.all(8),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  // Greeting Section
  Widget _buildGreeting() {
    return Row(
      children: [
        const Icon(Icons.lock_outline, color: Colors.white, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Welcome!',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              'Gesita Chady',
              style: TextStyle(
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

  // Balance Card
  Widget _buildBalanceCard() {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 33, 87, 168),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Total Balance', style: TextStyle(color: Colors.white70)),
              Icon(Icons.more_horiz, color: Colors.white),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '\$2,957',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _IncomeExpense(
                icon: Icons.arrow_downward,
                label: 'Income',
                amount: '\$1,200',
                color: Colors.transparent,
              ),
              _IncomeExpense(
                icon: Icons.arrow_upward,
                label: 'Expenses',
                amount: '\$1,300',
                color: Colors.transparent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===== Reusable Income / Expense Widget =====
class _IncomeExpense extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color color;

  const _IncomeExpense({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
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
        print('Tapped ${item.label}');
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
