import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

void showForgotPasswordDialog(BuildContext context, {String? initialEmail}) {
  final emailController = TextEditingController(text: initialEmail);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reset Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your email address to receive a password reset link.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final email = emailController.text.trim();
            if (email.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter your email')),
              );
              return;
            }

            // Show loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            );

            String? errorMessage;
            try {
              await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
            } on FirebaseAuthException catch (e) {
              errorMessage = e.message ?? 'Failed to send reset email';
            } catch (e) {
              errorMessage = 'Failed to send reset email: $e';
            }

            if (context.mounted) {
              // Close loading
              Navigator.pop(context);
              if (errorMessage == null) {
                // Close input dialog
                Navigator.pop(context);
                // Show standardized success
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Email Sent'),
                    content: Text(
                      'Email sent! Check Inbox & Spam folder for $email',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorMessage)),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCFA6A6), // Dusty Rose
            foregroundColor: Colors.white,
          ),
          child: const Text('Send Link'),
        ),
      ],
    ),
  );
}
