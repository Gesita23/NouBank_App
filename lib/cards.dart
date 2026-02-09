import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bottom_nav.dart';

// DESIGN CONSTANTS - Matching Home.dart theme
const Color primarypurple = Color.fromARGB(255, 13, 71, 161);
const Color secondarypurple = Color.fromARGB(255, 21, 101, 192);

class CardScreen extends StatefulWidget {
  const CardScreen({super.key});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  bool lockCard = true;
  bool manageActivity = true;
  int _selectedIndex = 3; // Cards tab is selected

  void _onItemTapped(int index) {
    // Handle navigation to different pages
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/account');
        break;
      case 2:
        Navigator.pushNamed(context, '/transactions');
        break;
      case 3:
        // Already on Cards, just update selected index
        setState(() {
          _selectedIndex = index;
        });
        break;
      case 4:
        Navigator.pushNamed(context, '/more');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: const Center(
          child: Text('Please log in to view your cards'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Cards",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primarypurple),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final name = (data['name'] ?? 'User').toString().toUpperCase();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                /// CARD UI - Updated with theme colors
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [
                        primarypurple,
                        secondarypurple,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primarypurple.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// TOP ROW
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "NouBank",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Debit",
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            )
                          ],
                        ),
                        const Spacer(),
                        /// CARD HOLDER NAME - Dynamic from Firebase
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        /// VALID THRU + NFC + MASTERCARD
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Valid Thru\n05/2027",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const Icon(
                              Icons.wifi,
                              color: Colors.white,
                              size: 24,
                            ),
                            /// Mastercard Logo
                            Row(
                              children: const [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                ),
                                SizedBox(width: 4),
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.orange,
                                ),
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                /// ACTION LIST
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      /// LOCK CARD
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primarypurple.withOpacity(0.1),
                          child: const Icon(Icons.lock, color: primarypurple),
                        ),
                        title: const Text(
                          "Lock card",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text("Temporarily stop transactions."),
                        trailing: Switch(
                          value: lockCard,
                          activeColor: primarypurple,
                          onChanged: (value) {
                            setState(() {
                              lockCard = value;
                            });
                          },
                        ),
                      ),
                      const Divider(height: 0),
                      /// CHANGE PIN
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: secondarypurple.withOpacity(0.1),
                          child: const Icon(Icons.grid_view, color: secondarypurple),
                        ),
                        title: const Text(
                          "Change card PIN",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text("Choose a new PIN for your card."),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // TODO: Implement change PIN functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Change PIN feature coming soon'),
                              backgroundColor: primarypurple,
                            ),
                          );
                        },
                      ),
                      const Divider(height: 0),
                      /// MANAGE ACTIVITY
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primarypurple.withOpacity(0.1),
                          child: const Icon(Icons.credit_card, color: primarypurple),
                        ),
                        title: const Text(
                          "Manage card activity",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text("Set your card preferences."),
                        trailing: Switch(
                          value: manageActivity,
                          activeColor: primarypurple,
                          onChanged: (value) {
                            setState(() {
                              manageActivity = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
      /// BOTTOM NAV BAR - Using your custom bottom_nav.dart
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}