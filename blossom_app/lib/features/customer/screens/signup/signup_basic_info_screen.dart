import 'package:flutter/material.dart';
import 'package:blossom_app/features/customer/screens/signup/signup_layout.dart';
import 'package:blossom_app/features/customer/screens/signup/signup_password_screen.dart';

class SignUpBasicInfoScreen extends StatelessWidget {
  const SignUpBasicInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController referralController = TextEditingController();
    final theme = Theme.of(context);

    return SignUpLayout(
      title: 'Sign Up',
      subtitle:
          'Already have an account? Login', // In a real app, Login would be tappable
      onBack: () => Navigator.pop(context),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Email',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Referral Code (optional)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: referralController,
              decoration: const InputDecoration(
                hintText: 'ABC123',
                prefixIcon: Icon(Icons.card_giftcard_outlined),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
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

            Row(
              children: [
                Expanded(
                  child: Divider(color: Colors.black.withValues(alpha: 0.1)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Or sign up with',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: Colors.black.withValues(alpha: 0.1)),
                ),
              ],
            ),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(Icons.g_mobiledata, Colors.red, theme),
                const SizedBox(width: 20),
                _buildSocialButton(Icons.facebook, Colors.blue[900]!, theme),
                const SizedBox(width: 20),
                _buildSocialButton(Icons.apple, Colors.black, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color, ThemeData theme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IconButton(
        onPressed: () {},
        icon: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
