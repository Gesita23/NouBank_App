import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const Color primaryBlue = Color.fromARGB(255, 13, 71, 161);
const Color secondaryBlue = Color.fromARGB(255, 21, 101, 192);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isPasswordVisible = false;
  bool isLoading = false;
  
  // Biometric Variables
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricAvailable = false;
  bool _canUseBiometrics = false;
  final _secureStorage = const FlutterSecureStorage();
  
  // PIN Variables
  bool _isPINEnabled = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _checkPINAvailability();
    _loadLastLoggedInEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    bool isAvailable = false;
    bool canUse = false;
    
    try {
      isAvailable = await _localAuth.canCheckBiometrics;
      
      if (isAvailable) {
        final prefs = await SharedPreferences.getInstance();
        final isEnabled = prefs.getBool('biometric_enabled') ?? false;
        
        final storedEmail = await _secureStorage.read(key: 'biometric_email');
        final storedPassword = await _secureStorage.read(key: 'biometric_password');
        
        canUse = isEnabled && storedEmail != null && storedPassword != null;
        
        if (storedEmail != null && mounted) {
          _emailController.text = storedEmail;
        }
      }

      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable;
          _canUseBiometrics = canUse;
        });
      }
    } catch (e) {
      print("Error checking biometrics: $e");
    }
  }

  Future<void> _checkPINAvailability() async {
    try {
      final storedPIN = await _secureStorage.read(key: 'user_pin');
      final storedEmail = await _secureStorage.read(key: 'pin_email');
      
      if (mounted) {
        setState(() {
          _isPINEnabled = storedPIN != null && storedEmail != null;
          if (storedEmail != null && _emailController.text.isEmpty) {
            _emailController.text = storedEmail;
          }
        });
      }
    } catch (e) {
      print("Error checking PIN: $e");
    }
  }

  Future<void> _loadLastLoggedInEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString('last_logged_in_email');
    if (lastEmail != null && mounted && _emailController.text.isEmpty) {
      setState(() {
        _emailController.text = lastEmail;
      });
    }
  }

  void _toggleAuthMode() {
    setState(() {
      isLogin = !isLogin;
      _formKey.currentState?.reset();
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: primaryBlue),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  Future<bool> _checkUsernameAvailability(String username) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return querySnapshot.docs.isEmpty;
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        final email = await _secureStorage.read(key: 'biometric_email');
        final password = await _secureStorage.read(key: 'biometric_password');
        
        if (email == null || password == null) {
          _showErrorDialog('Biometric credentials not found. Please login normally first.');
          return;
        }

        setState(() => isLoading = true);

        try {
          await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          if (mounted) {
            _showSuccessSnackbar('Biometric Login Successful!');
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
          }
        } on FirebaseAuthException catch (e) {
          await _secureStorage.delete(key: 'biometric_email');
          await _secureStorage.delete(key: 'biometric_password');
          
          String errorMessage = 'Login failed. Please enter your credentials.';
          if (e.code == 'user-not-found') {
            errorMessage = 'Account not found. Please login normally.';
          } else if (e.code == 'wrong-password') {
            errorMessage = 'Stored credentials are invalid. Please login normally.';
          }
          
          _showErrorDialog(errorMessage);
          setState(() => _canUseBiometrics = false);
        } finally {
          if (mounted) setState(() => isLoading = false);
        }
      }
    } catch (e) {
      print("Biometric Error: $e");
      if (mounted) {
        _showErrorDialog('Biometric authentication failed. Please try again.');
      }
    }
  }

  Future<void> _authenticateWithPIN() async {
    final pinController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.pin, color: primaryBlue, size: 28),
            SizedBox(width: 12),
            Text('Enter PIN'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your 4-digit PIN to login',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryBlue, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              pinController.dispose();
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a 4-digit PIN'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final storedPIN = await _secureStorage.read(key: 'user_pin');
                final email = await _secureStorage.read(key: 'pin_email');
                final password = await _secureStorage.read(key: 'pin_password');
                
                if (storedPIN == null || email == null || password == null) {
                  Navigator.of(ctx).pop();
                  _showErrorDialog('PIN not set up. Please login normally and set up a PIN in Settings.');
                  return;
                }

                if (pinController.text == storedPIN) {
                  Navigator.of(ctx).pop();
                  setState(() => isLoading = true);

                  try {
                    await _auth.signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                    
                    if (mounted) {
                      _showSuccessSnackbar('PIN Login Successful!');
                      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                    }
                  } on FirebaseAuthException catch (e) {
                    await _secureStorage.delete(key: 'user_pin');
                    await _secureStorage.delete(key: 'pin_email');
                    await _secureStorage.delete(key: 'pin_password');
                    
                    String errorMessage = 'Login failed. Please enter your credentials.';
                    if (e.code == 'user-not-found') {
                      errorMessage = 'Account not found. Please login normally.';
                    } else if (e.code == 'wrong-password') {
                      errorMessage = 'Stored credentials are invalid. Please login normally.';
                    }
                    
                    _showErrorDialog(errorMessage);
                    setState(() => _isPINEnabled = false);
                  } finally {
                    if (mounted) setState(() => isLoading = false);
                  }
                } else {
                  Navigator.of(ctx).pop();
                  _showErrorDialog('Incorrect PIN. Please try again.');
                }
              } catch (e) {
                Navigator.of(ctx).pop();
                _showErrorDialog('Error verifying PIN. Please try again.');
              }
              
              pinController.dispose();
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: const Text('Verify', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_logged_in_email', _emailController.text.trim());
        
        _showSuccessSnackbar('Login successful!');
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      } else {
        final isUsernameAvailable = await _checkUsernameAvailability(_usernameController.text.trim());
        if (!isUsernameAvailable) {
          _showErrorDialog('Username already taken. Please choose another.');
          setState(() => isLoading = false);
          return;
        }

        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final uid = userCredential.user!.uid;

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
          'username': _usernameController.text.trim().toLowerCase(),
          'phone': _phoneController.text.trim(),
          'account_balance': 0.0,
          'income': 0.00,
          'expenses': 0.00,
          'created_at': FieldValue.serverTimestamp(),
        });
        
        _showSuccessSnackbar('Account created successfully!');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password': errorMessage = 'Password is too weak.'; break;
        case 'email-already-in-use': errorMessage = 'Email already registered.'; break;
        case 'user-not-found': errorMessage = 'No account found.'; break;
        case 'wrong-password': errorMessage = 'Incorrect password.'; break;
        case 'invalid-email': errorMessage = 'Invalid email.'; break;
        default: errorMessage = e.message ?? 'Login failed.';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog('An error occurred.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorDialog('Please enter your email address first.');
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSuccessSnackbar('Password reset email sent!');
    } catch (e) {
      _showErrorDialog('Failed to send reset email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryBlue, secondaryBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 60),
                  _buildAuthCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: const Icon(Icons.account_balance, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 20),
        const Text('NouBank', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Text(isLogin ? 'Welcome back!' : 'Create your account', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16)),
      ],
    );
  }

  Widget _buildAuthCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isLogin ? 'Sign In' : 'Sign Up', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryBlue), textAlign: TextAlign.center),
            const SizedBox(height: 30),

            if (!isLogin) ...[
              _buildTextField(controller: _nameController, label: 'Full Name', icon: Icons.person_outline, validator: (v) => v!.isEmpty ? 'Enter name' : null),
              const SizedBox(height: 16),
              _buildTextField(controller: _usernameController, label: 'Username', icon: Icons.alternate_email, validator: (v) => v!.length < 3 ? 'Username too short' : null),
              const SizedBox(height: 16),
              _buildTextField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, maxLength: 8, validator: (v) => v!.length != 8 ? 'Invalid phone' : null),
              const SizedBox(height: 16),
            ],

            _buildTextField(controller: _emailController, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) => !v!.contains('@') ? 'Invalid email' : null),
            const SizedBox(height: 16),

            _buildTextField(controller: _passwordController, label: 'Password', icon: Icons.lock_outline, isPassword: true, validator: (v) => v!.length < 6 ? 'Password too short' : null),

            if (isLogin) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _resetPassword, child: const Text('Forgot Password?', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600))),
              ),
            ],

            const SizedBox(height: 24),
            _buildSubmitButton(),
            
            // Quick Login Options
            if (isLogin && (_canUseBiometrics || _isPINEnabled)) ...[
              const SizedBox(height: 16),
              const Divider(thickness: 1),
              const SizedBox(height: 8),
              const Text(
                'Quick Login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_isPINEnabled) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.pin, size: 24),
                        label: const Text('PIN Login'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryBlue,
                          side: const BorderSide(color: primaryBlue, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading ? null : _authenticateWithPIN,
                      ),
                    ),
                    if (_canUseBiometrics) const SizedBox(width: 12),
                  ],
                  if (_canUseBiometrics) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.fingerprint, size: 24),
                        label: const Text('Biometric'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryBlue,
                          side: const BorderSide(color: primaryBlue, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading ? null : _authenticateWithBiometrics,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            const SizedBox(height: 20),
            _buildToggleAuthMode(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text, bool isPassword = false, String? Function(String?)? validator, int? maxLength}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && !isPasswordVisible,
      validator: validator,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        counterText: maxLength != null ? '' : null,
        prefixIcon: Icon(icon, color: primaryBlue),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                icon: Icon(isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue, width: 2)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue], begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(isLogin ? 'Sign In' : 'Sign Up', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildToggleAuthMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(isLogin ? "Don't have an account? " : "Already have an account? ", style: TextStyle(color: Colors.grey[700])),
        TextButton(
          onPressed: _toggleAuthMode,
          child: Text(isLogin ? 'Sign Up' : 'Sign In', style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}