import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:blossom_app/features/customer/screens/signup/signup_layout.dart';
import 'package:blossom_app/features/customer/screens/signup/signup_complete_screen.dart';

class SignUpEmailVerificationScreen extends StatefulWidget {
  const SignUpEmailVerificationScreen({super.key});

  @override
  State<SignUpEmailVerificationScreen> createState() =>
      _SignUpEmailVerificationScreenState();
}

class _SignUpEmailVerificationScreenState
    extends State<SignUpEmailVerificationScreen> {
  bool _isEmailVerified = false;
  Timer? _timer;
  bool _canResendEmail = false;
  int _resendCountdown = 30;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    // Start checking for verification periodically
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkEmailVerified(),
    );

    // Start resend countdown
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResendEmail = false;
      _resendCountdown = 30;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        setState(() {
          _canResendEmail = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _checkEmailVerified() async {
    if (_isEmailVerified) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        _timer?.cancel();
        if (mounted) {
          setState(() {
            _isEmailVerified = true;
          });

          // Show verified state for a moment
          await Future.delayed(const Duration(seconds: 2));

          if (mounted) {
            // Navigate to success/complete screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const SignUpCompleteScreen(),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email resent!')),
        );
        _startResendTimer();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending email: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return SignUpLayout(
      title: 'Verify Email',
      subtitle: 'We sent a confirmation link to ${user?.email ?? "your email"}',
      // Prevent going back to ensure flow integrity or allow back to restart?
      // Allowing back might be confusing if user is already created.
      onBack: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_unread_outlined,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Check your inbox',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Click on the link in the email to complete your registration.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),

          if (_isEmailVerified)
            const Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 40),
                SizedBox(height: 8),
                Text(
                  'Verified!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),

          const Spacer(),

          TextButton(
            onPressed: _canResendEmail ? _resendVerificationEmail : null,
            child: Text(
              _canResendEmail
                  ? "Resend Email"
                  : "Resend Email in ${_resendCountdown}s",
              style: TextStyle(
                color: _canResendEmail
                    ? theme.colorScheme.primary
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // Manual check
                _checkEmailVerified();
                // If not verified, maybe show message?
                if (!_isEmailVerified) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Waiting for verification... Click the link in your email.',
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'I have verified',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
