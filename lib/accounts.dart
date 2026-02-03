import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bottom_nav.dart';

const Color primaryBlue = Color.fromARGB(255, 13, 71, 161);
const Color secondaryBlue = Color.fromARGB(255, 21, 101, 192);

class BankAccount {
  final String id;
  final String accountType;
  final double balance;
  final String accountNumber;
  final String holderName;
  final Color cardColor;
  final IconData icon;

  BankAccount({
    required this.id,
    required this.accountType,
    required this.balance,
    required this.accountNumber,
    required this.holderName,
    required this.cardColor,
    required this.icon,
  });
}

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        break;
      case 1:
        break;
      case 2:
        Navigator.pushNamed(context, '/transactions');
        break;
      case 3:
        Navigator.pushNamed(context, '/cards');
        break;
      case 4:
        Navigator.pushNamed(context, '/more');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Accounts',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: primaryBlue,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  );
                }

                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final name = data['name'] ?? 'User';
                final balance =
                    (data['account_balance'] ?? 0).toDouble();

                final accounts = [
                  BankAccount(
                    id: 'main',
                    accountType: 'Main Account',
                    balance: balance,
                    accountNumber: '****1234',
                    holderName: name,
                    cardColor: primaryBlue,
                    icon: Icons.account_balance_wallet,
                  ),
                ];

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    children: [
                      _buildHeader(balance, name),
                      const SizedBox(height: 24),
                      _buildAccounts(accounts),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildHeader(double balance, String name) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBlue, secondaryBlue],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hello, $name',
              style:
                  const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Total Balance',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Text('\$${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAccounts(List<BankAccount> accounts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: accounts.map(_buildAccountCard).toList(),
      ),
    );
  }

  Widget _buildAccountCard(BankAccount account) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AccountDetailsPage(account: account),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                account.cardColor,
                account.cardColor.withOpacity(0.8)
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(account.icon, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(account.accountType,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Icon(Icons.chevron_right,
                      color: Colors.white70),
                ],
              ),
              const SizedBox(height: 20),
              Text(account.accountNumber,
                  style: const TextStyle(
                      color: Colors.white, letterSpacing: 2)),
              const SizedBox(height: 16),
              Text('\$${account.balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountDetailsPage extends StatelessWidget {
  final BankAccount account;

  const AccountDetailsPage({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(account.accountType,
            style:
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: account.cardColor,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  account.cardColor,
                  account.cardColor.withOpacity(0.8)
                ],
              ),
            ),
            child: Column(
              children: [
                Icon(account.icon, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text('\$${account.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/payments',
                  arguments: {
                    'accountType': account.accountType,
                    'accountBalance': account.balance,
                    'accountNumber': account.accountNumber,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: account.cardColor,
              ),
              child: const Text('Send Money'),
            ),
          ),
        ],
      ),
    );
  }
}
