// This screen is displayed upon successful user registration.
// It provides feedback to the user and a button to proceed to the login screen.

import 'package:flutter/material.dart';
import 'package:blossom_app/features/auth/screens/login_screen.dart';

class SignUpCompleteScreen extends StatelessWidget {
  const SignUpCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // A decorative icon to visually confirm success.
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 30),
              
              // Welcome message.
              Text(
                'Welcome to Blossom!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              
              // Confirmation text.
              Text(
                'Your account has been created successfully.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Button to navigate to the login screen.
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Removes all previous routes and navigates to the LoginScreen,
                    // preventing the user from going back to the sign-up flow.
                     Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Login to Continue',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
