// This screen provides a login interface specifically for admin users.
// It validates user credentials and restricts access to accounts with emails
// starting with 'admin'.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_layout.dart'; // The main layout for the admin panel after login.

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false; // Manages the loading state of the sign-in button.

  // Handles the entire sign-in process, including validation and Firebase authentication.
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Basic validation for empty fields.
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Security check: Only allows emails that start with 'admin' to attempt login.
    if (!email.startsWith('admin')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Access Denied: Only admin accounts (starting with "admin") are allowed.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Attempt to sign in with the provided credentials using Firebase Auth.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // On successful login, replace the current screen with the admin main layout.
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Display any Firebase authentication errors (e.g., wrong password) to the user.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Authentication failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Catch any other unexpected errors during the process.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Ensure the loading indicator is turned off, regardless of outcome.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Clean up the controllers when the widget is removed from the tree to prevent memory leaks.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Defines the visual theme and colors for the admin login screen.
    const Color backgroundColor = Color(0xFFEEE6D3);
    const Color cardColor = Color(0xFFBFB59B);
    const Color buttonColor = Color(0xFF5D5343);
    const Color inputFillColor = Color(0xFFFDFCF2);
    const Color textColor = Color(0xFF333333);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            // Main layout with a centered card for the login form.
            child: Container(
              width: 500, // Fixed width for a consistent look on larger screens.
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo and branding.
                  const Icon(
                    Icons.local_florist_outlined,
                    size: 80,
                    color: Color(0xFF5D5343),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'BLOSSOM',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                      color: Color(0xFF5D5343),
                    ),
                  ),
                  const Text(
                    'BEAUTY & WELLNESS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1,
                      color: Color(0xFF5D5343),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Header text.
                  const Text(
                    'Login to Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Please enter your email and password to continue',
                    style: TextStyle(fontSize: 14, color: Color(0xFF4A4A4A)),
                  ),
                  const SizedBox(height: 40),

                  // Email input field.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Email Address',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputFillColor,
                      hintText: 'admin1@blossom.my',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password input field.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true, // Hides password characters.
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputFillColor,
                      hintText: '********',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Placeholder for password recovery.
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Forget Password?',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign In button with loading indicator.
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
