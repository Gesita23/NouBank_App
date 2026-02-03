import 'package:flutter/material.dart';
import 'home.dart';
import 'auth_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'transactions.dart';
import 'more.dart';
import 'actiongrid/qr_scan.dart';
import '../accounts.dart';
import 'actiongrid/payments.dart';
import 'package:noubank/actiongrid/send_to_contact.dart';
import 'actiongrid/request_money.dart';
import 'actiongrid/pay_bills.dart';
import 'actiongrid/bank_transfer.dart';
import 'actiongrid/others.dart';
import 'actiongrid/mobile_top_up.dart';
import 'actiongrid/currency_convertor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Banking App UI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 98, 9, 114),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),

      //routes baby
      routes: {
        //navbar
        '/home': (context) => const MyHomePage(title: ''),
        '/account': (context) => const AccountsPage(),
        '/transactions': (context) => const TransactionPage(),
        '/more': (context) => const MorePage(),

        /////FOR ACTIONGRID/////
        '/scan': (context) => const QrPaymentPage(),
        '/payments': (context) => const PaymentsPage(),
        '/send_to_contact': (context) => const SendToContactPage(),
        '/request_money': (context) => const RequestMoneyPage(),
        '/pay_bills': (context) => const PayBillsPage(),
        '/bank_transfer': (context) => const BankTransferPage(),
        // '/statistics':(context) => const StatisticsPage(),
        '/other': (context) => const OtherPage(),
        '/currency_converter': (context) => const CurrencyConverterPage(),
        '/mobile_topup': (context) => const MobileTopUpPage(),
      },
    );
  }
}

//wrapper to handle authentication

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        //show loading indicator while checking auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        //if user is logged in , show hscreen
        if (snapshot.hasData && snapshot.data != null) {
          return const MyHomePage(title: 'Banking App');
        }

        //if user is not logged in , show auth screen
        return const AuthScreen();
      },
    );
  }
}
