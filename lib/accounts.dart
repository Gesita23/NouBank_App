import 'package:flutter/material.dart';

// Matching the color from your PDF (home.dart source)
const Color primaryPurple = Color.fromARGB(255, 13, 71, 161);
const Color bgGrey = Color(0xFFF2F4F8);

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // Global visibility toggle for the "Total Balance" card
  bool _isTotalBalanceHidden = false;

  // Mock Data - In a real app, you might fetch this from Firestore like home.dart does
  List<Map<String, dynamic>> accounts = [
    {
      "id": 1,
      "name": "Savings Account",
      "number": "••• 2389",
      "balance": "\$25,150",
      "isHidden": false,
      "icon": Icons.savings_rounded,
      "iconColor": Colors.green
    },
    {
      "id": 2,
      "name": "Checking Account",
      "number": "••• 4756",
      "balance": "\$16,500",
      "isHidden": false,
      "icon": Icons.account_balance_wallet,
      "iconColor": Colors.redAccent
    },
    {
      "id": 3,
      "name": "Joint Account",
      "number": "••• 8907",
      "balance": ".....", 
      "isHidden": true, 
      "icon": Icons.groups,
      "iconColor": const Color(0xFF5C6BC0)
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: primaryPurple,
        elevation: 0,
        // The back button here will return you to the Home Page
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), 
        ),
        title: const Text(
          "Accounts",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. TOTAL BALANCE CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              decoration: const BoxDecoration(
                color: primaryPurple,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1), // Glassmorphism effect
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Total Balance",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isTotalBalanceHidden ? "••••••" : "\$64,350",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                             setState(() {
                               _isTotalBalanceHidden = !_isTotalBalanceHidden;
                             });
                          },
                          icon: Icon(
                            _isTotalBalanceHidden ? Icons.visibility_off : Icons.remove_red_eye,
                            color: Colors.white70,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Total balance across all accounts",
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // 2. ACCOUNTS LIST
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text("Your Accounts", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                  ),
                  
                  // Generate the cards dynamically from the list
                  ...accounts.map((acc) => _buildAccountCard(acc)).toList(),

                  const Padding(
                    padding: EdgeInsets.only(top: 24.0, bottom: 12.0),
                    child: Text("Other Accounts", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                  ),
                   // Example of static other account
                  _buildAccountCard({
                    "name": "Loan Account",
                    "number": "••• 1122",
                    "balance": "\$4,200",
                    "isHidden": false,
                    "icon": Icons.monetization_on,
                    "iconColor": Colors.orange
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> data) {
    bool isHidden = data['isHidden'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (data['iconColor'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)
            ),
            child: Icon(data['icon'], color: data['iconColor'], size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)),
                ),
                const SizedBox(height: 4),
                Text(
                  data['number'], 
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                isHidden ? "••••••" : data['balance'],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    // Update the specific account's visibility
                    if(accounts.contains(data)) {
                       data['isHidden'] = !isHidden;
                    }
                  });
                },
                child: Icon(
                  isHidden ? Icons.visibility_off : Icons.remove_red_eye,
                  color: const Color(0xFF8B95A6),
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}