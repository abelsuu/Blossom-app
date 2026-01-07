import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:blossom_app/features/customer/screens/signup/signup_layout.dart';
import 'package:blossom_app/features/customer/screens/signup/signup_email_verification_screen.dart';

class SignUpPasswordScreen extends StatelessWidget {
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
          Text(
            'Password',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Enter password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Confirm Password',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Re-enter password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
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
                  UserCredential userCredential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                        email: email,
                        password: passwordController.text,
                      );

                  // Update display name
                  await userCredential.user?.updateDisplayName(name);

                  // Store user data in Realtime Database
                  if (userCredential.user != null) {
                    final uid = userCredential.user!.uid;
                    final isStaff = email.endsWith('@blossom.my');

                    if (isStaff) {
                      // STAFF: Write to 'staffs' node
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
                      // CUSTOMER: Write to 'users' node
                      DatabaseReference ref = FirebaseDatabase.instance.ref(
                        "users/$uid",
                      );
                      // Root data
                      await ref.update({
                        "name": name,
                        "email": email,
                        "role": "customer",
                      });
                      // Profile data (for Admin UsersScreen visibility)
                      await ref.child('profile').update({
                        "name": name,
                        "email": email,
                        "firstName": name.split(' ').first,
                        "lastName": name.split(' ').length > 1
                            ? name.split(' ').sublist(1).join(' ')
                            : '',
                        "createdAt": ServerValue.timestamp,
                      });
                      final code = uid.substring(0, 6).toUpperCase();
                      await ref.update({"referralCode": code});
                      await FirebaseDatabase.instance
                          .ref("referral_codes/$code")
                          .set({"ownerUid": uid});
                      final provided = referralCode?.trim();
                      if (provided != null && provided.isNotEmpty) {
                        final rcSnap = await FirebaseDatabase.instance
                            .ref("referral_codes/$provided")
                            .get();
                        if (rcSnap.exists) {
                          final data = Map<String, dynamic>.from(
                            rcSnap.value as Map,
                          );
                          final ownerUid = data["ownerUid"];
                          if (ownerUid != null && ownerUid != uid) {
                            final referrerLoyalty =
                                FirebaseDatabase.instance
                                    .ref("users/$ownerUid/loyalty");
                            final refereeLoyalty =
                                FirebaseDatabase.instance
                                    .ref("users/$uid/loyalty");
                            final referrerSnap = await referrerLoyalty.get();
                            final refereeSnap = await refereeLoyalty.get();
                            int refPoints = 0;
                            int rePoints = 0;
                            if (referrerSnap.exists) {
                              final m = Map<String, dynamic>.from(
                                  referrerSnap.value as Map);
                              refPoints = m["points"] as int? ?? 0;
                            }
                            if (refereeSnap.exists) {
                              final m = Map<String, dynamic>.from(
                                  refereeSnap.value as Map);
                              rePoints = m["points"] as int? ?? 0;
                            }
                            await referrerLoyalty.update(
                              {"points": refPoints + 10},
                            );
                            await refereeLoyalty.update({"points": rePoints + 5});
                            await FirebaseDatabase.instance
                                .ref("users/$ownerUid/loyalty/history")
                                .push()
                                .set({
                              "type": "earned",
                              "amount": 10,
                              "date": ServerValue.timestamp,
                              "description": "Referral reward",
                              "refereeUid": uid
                            });
                            await FirebaseDatabase.instance
                                .ref("users/$uid/loyalty/history")
                                .push()
                                .set({
                              "type": "earned",
                              "amount": 5,
                              "date": ServerValue.timestamp,
                              "description": "Referral join reward",
                              "referrerUid": ownerUid
                            });
                            await FirebaseDatabase.instance
                                .ref("referrals/redemptions/$uid")
                                .set({
                              "code": provided,
                              "referrerUid": ownerUid,
                              "timestamp": ServerValue.timestamp
                            });
                          }
                        }
                      }
                    }

                    // Send verification email
                    await userCredential.user?.sendEmailVerification();

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignUpEmailVerificationScreen(),
                        ),
                      );
                    }
                  }
                } on FirebaseAuthException catch (e) {
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
