// This screen collects basic user information during the signup process,
// including name, email, and an optional referral code.

import 'package:flutter/material.dart';
import 'package:blossom_app/features/customer/screens/signup/signup_layout.dart';
import 'package:blossom_app/features/customer/screens/signup/signup_password_screen.dart';

/// A screen for users to enter their basic information (name, email) as part of the sign-up flow.
///
/// This screen includes fields for name, email, and an optional referral code.
/// Upon completion, it navigates to the [SignUpPasswordScreen], passing the entered data.
class SignUpBasicInfoScreen extends StatelessWidget {
  /// Creates a [SignUpBasicInfoScreen].
  const SignUpBasicInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controllers to manage the text input for name, email, and referral code.
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController referralController = TextEditingController();
    final theme = Theme.of(context);

    // Uses a common layout for sign-up screens.
    return SignUpLayout(
      title: 'Sign Up',
      subtitle:
          'Already have an account? Login', // In a real app, Login would be tappable
      onBack: () => Navigator.pop(context),
      child: SingleChildScrollView(
        // Enables scrolling to prevent overflow on smaller screens.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label for the name input field.
            Text(
              'Name',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Text field for the user's name.
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),
            // Label for the email input field.
            Text(
              'Email',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Text field for the user's email address.
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 20),
            // Label for the optional referral code field.
            Text(
              'Referral Code (optional)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Text field for the referral code.
            TextField(
              controller: referralController,
              decoration: const InputDecoration(
                hintText: 'ABC123',
                prefixIcon: Icon(Icons.card_giftcard_outlined),
              ),
            ),
            const SizedBox(height: 30),
            // The main action button to proceed to the next step.
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Navigates to the password screen, passing along the collected info.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignUpPasswordScreen(
                        email: emailController.text.trim(),
                        name: nameController.text.trim(),
                        referralCode: referralController.text.trim(),
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Visual divider with text, offering alternative sign-up options.
            Row(
              children: [
                Expanded(
                  child: Divider(color: Colors.black.withOpacity(0.1)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Or sign up with',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: Colors.black.withOpacity(0.1)),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // A row of social media sign-up buttons.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google sign-up button.
                _buildSocialButton(Icons.g_mobiledata, Colors.red, theme),
                const SizedBox(width: 20),
                // Facebook sign-up button.
                _buildSocialButton(Icons.facebook, Colors.blue[900]!, theme),
                const SizedBox(width: 20),
                // Apple sign-up button.
                _buildSocialButton(Icons.apple, Colors.black, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// A helper widget to build the circular social media icon buttons.
  ///
  /// This creates a consistent style for the social login buttons.
  Widget _buildSocialButton(IconData icon, Color color, ThemeData theme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IconButton(
        onPressed: () {
          // Placeholder for social media sign-in logic.
          // In a real app, this would trigger the respective social sign-in flow.
        },
        icon: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
