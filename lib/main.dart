import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home.dart';
import 'auth_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'transactions.dart';
import 'more.dart';
import 'actiongrid/qr_scan.dart';
import 'accounts.dart';
import 'actiongrid/payments.dart';
import 'package:noubank/actiongrid/send_to_contact.dart';
import 'actiongrid/request_money.dart';
import 'actiongrid/pay_bills.dart';
import 'actiongrid/bank_transfer.dart';
import 'actiongrid/others.dart';
import 'actiongrid/mobile_top_up.dart';
import 'actiongrid/currency_convertor.dart';
import 'cards.dart';
import 'actiongrid/statistics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable all orientations for responsive support
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
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
        '/home': (context) => MyHomePage(title: ''),
        '/account': (context) => AccountScreen(),
        '/transactions': (context) => TransactionPage(),
        '/more': (context) => MorePage(),
        '/cards': (context) => CardScreen(),

        /////FOR ACTIONGRID/////
        '/scan': (context) => QrPaymentPage(),
        '/payments': (context) => PaymentsPage(),
        '/send_to_contact': (context) => SendToContactPage(),
        '/request_money': (context) => RequestMoneyPage(),
        '/pay_bills': (context) => PayBillsPage(),
        '/bank_transfer': (context) => BankTransferPage(),
        '/statistics':(context) => StatisticsScreen(),
        '/other': (context) => OtherPage(),
        '/currency_converter': (context) => CurrencyConverterPage(),
        '/mobile_topup': (context) => MobileTopUpPage(),
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
          return MyHomePage(title: 'Banking App');
        }

        //if user is not logged in , show auth screen
        return AuthScreen();
      },
    );
  }
}