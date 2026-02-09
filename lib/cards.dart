import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CardScreen(),
    );
  }
}

class CardScreen extends StatefulWidget {
  const CardScreen({super.key});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  bool lockCard = true;
  bool manageActivity = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),

      body: Column(
        children: [
          /// ===== HEADER =====
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 170,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 21, 58, 110),
                      Color.fromARGB(255, 19, 72, 119),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "My Cards",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Manage your debit card",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    Icon(Icons.notifications_none, color: Colors.white, size: 28)
                  ],
                ),
              ),

              /// CARD FLOATING
              Positioned(
                left: 16,
                right: 16,
                bottom: -90,
                child: _buildDebitCard(),
              ),
            ],
          ),

          const SizedBox(height: 110),

          /// ===== ACTION LIST =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    icon: Icons.lock,
                    color: const Color.fromARGB(255, 21, 58, 110),
                    title: "Lock card",
                    subtitle: "Temporarily stop transactions.",
                    value: lockCard,
                    onChanged: (v) => setState(() => lockCard = v),
                  ),
                  const Divider(height: 0),

                  _buildArrowTile(
                    icon: Icons.grid_view,
                    color: const Color.fromARGB(255, 21, 58, 110),
                    title: "Change card PIN",
                    subtitle: "Choose a new PIN for your card.",
                  ),
                  const Divider(height: 0),

                  _buildSwitchTile(
                    icon: Icons.credit_card,
                    color: const Color.fromARGB(255, 21, 58, 110),
                    title: "Manage card activity",
                    subtitle: "Set your card preferences.",
                    value: manageActivity,
                    onChanged: (v) => setState(() => manageActivity = v),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      /// ===== BOTTOM NAV =====
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        selectedItemColor: const Color.fromARGB(255, 21, 58, 110),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: "Accounts"),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: "Transact"),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: "Cards"),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "More"),
        ],
      ),
    );
  }

  /// ===== CARD WIDGET =====
  Widget _buildDebitCard() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 21, 58, 110),
            Color.fromARGB(255, 19, 72, 119),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("NouBank",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text("Debit", style: TextStyle(color: Colors.white70)),
            ],
          ),
          const Spacer(),
          const Text(
            "User",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Valid Thru\n05/2027",
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const Icon(Icons.wifi, color: Colors.white),
              Row(
                children: const [
                  CircleAvatar(radius: 12, backgroundColor: Colors.red),
                  SizedBox(width: 4),
                  CircleAvatar(radius: 12, backgroundColor: Colors.orange),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        activeColor: color,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildArrowTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}  