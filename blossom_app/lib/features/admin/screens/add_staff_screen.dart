import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AddStaffScreen extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String? staffId;
  final Map<String, dynamic>? initialData;

  const AddStaffScreen({
    super.key,
    required this.onSave,
    required this.onCancel,
    this.staffId,
    this.initialData,
  });

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _roleController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _contactController = TextEditingController();
  bool _isSaving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _nameController.text = widget.initialData!['name'] ?? '';
      _emailController.text = widget.initialData!['email'] ?? '';
      _roleController.text = widget.initialData!['role'] ?? '';
      _contactController.text = widget.initialData!['contact'] ?? '';

      final address = widget.initialData!['address'] ?? '';
      final parts = address.toString().split(', ');
      if (parts.isNotEmpty) _address1Controller.text = parts[0];
      if (parts.length > 1)
        _address2Controller.text = parts.sublist(1).join(', ');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _roleController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _saveStaff() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final role = _roleController.text.trim();
    final address1 = _address1Controller.text.trim();
    final address2 = _address2Controller.text.trim();
    final contact = _contactController.text.trim();

    // 1. Basic Validation
    if (name.isEmpty || email.isEmpty || role.isEmpty || contact.isEmpty) {
      _showSnackBar('Please fill in required fields');
      return;
    }

    if (!email.startsWith('staff')) {
      _showSnackBar('Email must start with "staff"');
      return;
    }

    // Password validation (Required for new staff only)
    if (widget.staffId == null) {
      if (password.isEmpty) {
        _showSnackBar('Password is required for new staff');
        return;
      }
      if (password.length < 6) {
        _showSnackBar('Password must be at least 6 characters');
        return;
      }
      if (password != confirmPassword) {
        _showSnackBar('Passwords do not match');
        return;
      }
    }

    // 2. Admin Password Confirmation
    final adminPassword = await _showAdminPasswordDialog();
    if (adminPassword == null) return; // Cancelled

    setState(() {
      _isSaving = true;
    });

    try {
      // 3. Verify Admin Credentials
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw 'Admin not logged in';

      final cred = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: adminPassword,
      );

      // Re-authenticate admin
      await currentUser.reauthenticateWithCredential(cred);

      final fullAddress = address2.isNotEmpty
          ? '$address1, $address2'
          : address1;

      // 4. Perform Operation
      if (widget.staffId != null) {
        // --- EDIT STAFF ---
        await _updateStaff(
          uid: widget.staffId!,
          name: name,
          email: email,
          role: role,
          address: fullAddress,
          contact: contact,
          password: password.isNotEmpty ? password : null,
        );
        _showSnackBar('Staff updated successfully!');
      } else {
        // --- ADD NEW STAFF ---
        await _createStaff(
          name: name,
          email: email,
          password: password,
          role: role,
          address: fullAddress,
          contact: contact,
        );
        _showSnackBar('Staff added successfully!');
      }

      widget.onSave();
    } catch (e) {
      _showSnackBar('Operation failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _createStaff({
    required String name,
    required String email,
    required String password,
    required String role,
    required String address,
    required String contact,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // Initialize secondary app to create user without signing out admin
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final userCredential = await FirebaseAuth.instanceFor(
        app: secondaryApp,
      ).createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      // Create Database Entry
      await FirebaseDatabase.instance.ref('staffs/$uid').set({
        'name': name,
        'email': email,
        'role': role,
        'address': address,
        'contact': contact,
        'status': 'Active',
        'createdAt': ServerValue.timestamp,
        'firstName': name.split(' ').first,
        'lastName': name.split(' ').length > 1
            ? name.split(' ').sublist(1).join(' ')
            : '',
      });
    } finally {
      await secondaryApp?.delete();
    }
  }

  Future<void> _updateStaff({
    required String uid,
    required String name,
    required String email,
    required String role,
    required String address,
    required String contact,
    String? password,
  }) async {
    // Update Database
    await FirebaseDatabase.instance.ref('staffs/$uid').update({
      'name': name,
      'email': email,
      'role': role,
      'address': address,
      'contact': contact,
      'updatedAt': ServerValue.timestamp,
      'firstName': name.split(' ').first,
      'lastName': name.split(' ').length > 1
          ? name.split(' ').sublist(1).join(' ')
          : '',
    });

    // Update password using Cloud Functions (Admin SDK)
    if (password != null && password.isNotEmpty) {
      try {
        debugPrint(
          'Attempting to update password for UID: $uid via Cloud Functions...',
        );
        final result = await FirebaseFunctions.instance
            .httpsCallable('updateUserPassword')
            .call({'uid': uid, 'password': password});

        debugPrint('Password update result: ${result.data}');
      } catch (e) {
        debugPrint('Failed to update password via Cloud Function: $e');
        // Re-throw to be caught by _saveStaff and shown in SnackBar
        throw 'Database updated, but password update failed: ${e.toString()}';
      }
    }
  }

  Future<String?> _showAdminPasswordDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Admin Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your admin password to confirm this action.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            message.contains('failed') ||
                message.contains('Error') ||
                message.contains('match') ||
                message.contains('required')
            ? Colors.red
            : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Staff Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D5343),
                    ),
                  ),
                  Text(
                    'Welcome back! Admin 1',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5D5343),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Admin1',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Form
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Name'),
                      _buildTextField(
                        controller: _nameController,
                        hintText: 'Blossom',
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('Email Address'),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'staff1@gmail.com',
                      ),
                      const SizedBox(height: 24),
                      if (widget.staffId == null) ...[
                        _buildLabel('Password'),
                        _buildTextField(
                          controller: _passwordController,
                          isPassword: true,
                          hintText: 'Min 6 characters',
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Retype Password'),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          isPassword: true,
                        ),
                      ] else ...[
                        _buildLabel('Password Update'),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'To change the password for an existing staff member, send them a password reset email.',
                                      style: TextStyle(
                                        color: Colors.brown.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    if (_emailController.text.isEmpty) {
                                      _showSnackBar(
                                        'Please enter an email address first',
                                      );
                                      return;
                                    }
                                    try {
                                      await FirebaseAuth.instance
                                          .sendPasswordResetEmail(
                                            email: _emailController.text.trim(),
                                          );
                                      _showSnackBar(
                                        'Email sent! Check Inbox & Spam folder for ${_emailController.text}',
                                      );
                                    } catch (e) {
                                      _showSnackBar(
                                        'Failed to send reset email: $e',
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.email_outlined),
                                  label: const Text(
                                    'Send Password Reset Email',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: const BorderSide(color: Colors.black),
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildLabel('Role'),
                      _buildTextField(
                        controller: _roleController,
                        hintText: 'ADMIN',
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 48),

                // Right Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Address'),
                      _buildTextField(
                        controller: _address1Controller,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _address2Controller,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('Contact'),
                      _buildTextField(controller: _contactController),
                      const SizedBox(height: 40),

                      // Buttons
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: widget.onCancel,
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 150,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveStaff,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5D5343),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isSaving
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        'Save',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF5D5343),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
      ),
    );
  }
}
