import 'package:flutter/material.dart';
import 'home.dart';

const Color primarypurple = Color.fromARGB(255, 13, 71, 161);
const Color secondarypurple = Color.fromARGB(255, 21, 101, 192);

//reusable nav bar
class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home, 'Home', 0),
            _navItem(Icons.account_balance_wallet, 'Account', 1),
            _navItem(Icons.compare_arrows, 'Transact', 2),
            _navItem(Icons.credit_card, 'Cards', 3),
            _navItem(Icons.more_horiz, 'More', 4),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? primarypurple : Colors.grey;

    return InkWell(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
