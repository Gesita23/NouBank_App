import 'package:flutter/material.dart';
import 'home.dart';
import 'auth_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'carts.dart';
import 'actiongrid/statistics.dart';
import 'actiongrid/qr_scan.dart';

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
        /////FOR NAVBAR/////
        '/home': (context) => const MyHomePage(title: '',),
        //'/account': (context) => const AccountPage(),
       // '/transactions': (context) => const TransactionPage(),
        '/carts': (context) => const CartsPage(),
        //'/security': (context) => const SecurityPage(),
        //'/change_password': (context) => const ChangePasswordPage(),


        /////FOR ACTIONGRID/////
        '/scan':(context) => const QrPaymentPage(),
        '/statistics':(context) => const StatisticsPage(),
        
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
