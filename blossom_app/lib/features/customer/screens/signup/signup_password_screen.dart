// This screen allows the user to set and confirm their password.
// It receives user details (email, name) from the previous screen.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:blossom_app/features/customer/screens/signup/signup_layout.dart';
import 'package:blossom_app/features/customer/screens/signup/signup_email_verification_screen.dart';

class SignUpPasswordScreen extends StatelessWidget {
  // User data passed from the SignUpBasicInfoScreen.
  final String email;
  final String name;
  final String? referralCode;

  const SignUpPasswordScreen({
    super.key,
    required this.email,
    required this.name,
    this.referralCode,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    final theme = Theme.of(context);

    return SignUpLayout(
      title: 'Set Password',
      subtitle: 'Create a secure password',
      onBack: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Password input field.
          Text(
            'Password',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: passwordController,
            obscureText: true, // Hides password text.
            decoration: const InputDecoration(
              hintText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 20),

          // Confirm Password input field.
          Text(
            'Confirm Password',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: confirmPasswordController,
            obscureText: true, // Hides password text.
            decoration: const InputDecoration(
              hintText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                // --- FORM VALIDATION ---
                if (passwordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passwords do not match'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                if (passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                try {
                  // --- FIREBASE AUTH: USER CREATION ---
                  UserCredential userCredential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                        email: email,
                        password: passwordController.text,
                      );

                  await userCredential.user?.updateDisplayName(name);

                  // --- FIREBASE RTDB: SAVE USER DATA ---
                  if (userCredential.user != null) {
                    final uid = userCredential.user!.uid;
                    // Distinguish between staff and regular customers based on email.
                    final isStaff = email.endsWith('@blossom.my');

                    if (isStaff) {
                      // Write to 'staffs' node for admin/staff users.
                      DatabaseReference ref = FirebaseDatabase.instance.ref(
                        "staffs/$uid",
                      );
                      await ref.set({
                        "name": name,
                        "email": email,
                        "role": "Staff",
                        "firstName": name.split(' ').first,
                        "lastName": name.split(' ').length > 1
                            ? name.split(' ').sublist(1).join(' ')
                            : '',
                        "status": "Active",
                      });
                    } else {
                      // Write to 'users' node for customers.
                      DatabaseReference ref = FirebaseDatabase.instance.ref(
                        "users/$uid",
                      );
                      await ref.update({
                        "name": name,
                        "email": email,
                        "role": "customer",
                      });
                      // Additional profile data for visibility in admin panels.
                      await ref.child('profile').update({
                        "name": name,
                        "email": email,
                        "firstName": name.split(' ').first,
                        "lastName": name.split(' ').length > 1
                            ? name.split(' ').sublist(1).join(' ')
                            : '',
                        "createdAt": ServerValue.timestamp,
                      });
                      
                      // --- REFERRAL CODE LOGIC ---
                      // Create and assign a new referral code for the new user.
                      final code = uid.substring(0, 6).toUpperCase();
                      await ref.update({"referralCode": code});
                      await FirebaseDatabase.instance
                          .ref("referral_codes/$code")
                          .set({"ownerUid": uid});
                      
                      // Process the referral code if one was provided during signup.
                      final provided = referralCode?.trim();
                      if (provided != null && provided.isNotEmpty) {
                        // Check if the provided referral code is valid.
                        final rcSnap = await FirebaseDatabase.instance
                            .ref("referral_codes/$provided")
                            .get();
                        if (rcSnap.exists) {
                          final data = Map<String, dynamic>.from(
                            rcSnap.value as Map,
                          );
                          final ownerUid = data["ownerUid"];
                          if (ownerUid != null && ownerUid != uid) {
                            // Award loyalty points to both referrer and referee.
                            // (Implementation details omitted for brevity)
                          }
                        }
                      }
                    }

                    // --- EMAIL VERIFICATION & NAVIGATION ---
                    await userCredential.user?.sendEmailVerification();

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpEmailVerificationScreen(),
                        ),
                      );
                    }
                  }
                } on FirebaseAuthException catch (e) {
                  // Handle Firebase-specific errors (e.g., email already in use).
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.message ?? 'Error creating account'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Create Account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
