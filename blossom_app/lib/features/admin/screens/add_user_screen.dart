import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

class AddUserScreen extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String? userId;
  final Map<String, dynamic>? initialData;

  const AddUserScreen({
    super.key,
    required this.onSave,
    required this.onCancel,
    this.userId,
    this.initialData,
  });

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime _dateJoined = DateTime.now();
  bool _isSaving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _nameController.text = widget.initialData!['name'] ?? '';
      _emailController.text = widget.initialData!['email'] ?? '';
      _phoneController.text = widget.initialData!['phone'] ?? '';

      // Parse date joined if available
      if (widget.initialData!['date'] != null) {
        try {
          // Attempt to parse 'dd MMM yyyy' format from the table display
          _dateJoined = DateFormat(
            'dd MMM yyyy',
          ).parse(widget.initialData!['date']);
        } catch (e) {
          // If parsing fails, default to now (or try parsing from timestamp if raw data was passed)
          _dateJoined = DateTime.now();
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateJoined,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5D5343),
              onPrimary: Colors.white,
              onSurface: Color(0xFF5D5343),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dateJoined) {
      setState(() {
        _dateJoined = picked;
      });
    }
  }

  Future<void> _saveUser() async {
    // 1. Validation
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (widget.userId == null) {
      // New User: Password is required
      if (_passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password is required for new users')),
        );
        return;
      }
      if (_passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password must be at least 6 characters'),
          ),
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
        return;
      }
    } else {
      // Edit User: Password is optional, but if provided must match
      if (_passwordController.text.isNotEmpty) {
        if (_passwordController.text.length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password must be at least 6 characters'),
            ),
          );
          return;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match')),
          );
          return;
        }
      }
    }

    // 2. Admin Confirmation
    final adminPasswordController = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
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
              controller: adminPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Admin Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      // 3. Verify Admin Password
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Admin not logged in');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: adminPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // 4. Create/Update User
      String targetUid = widget.userId ?? '';

      if (widget.userId == null) {
        // Create new user in Firebase Auth (using secondary app)
        FirebaseApp tempApp = await Firebase.initializeApp(
          name: 'tempApp_${DateTime.now().millisecondsSinceEpoch}',
          options: Firebase.app().options,
        );

        try {
          UserCredential userCredential =
              await FirebaseAuth.instanceFor(
                app: tempApp,
              ).createUserWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text,
              );
          targetUid = userCredential.user!.uid;
        } finally {
          await tempApp.delete();
        }
      } else {
        // Update User Profile in Realtime Database
        await FirebaseDatabase.instance.ref('users/$targetUid/profile').update({
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'updatedAt': ServerValue.timestamp,
        });
      }

      widget.onSave();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
                    'User Management',
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
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Full Name'),
                        _buildTextField(
                          controller: _nameController,
                          hintText: 'Jane Doe',
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Email Address'),
                        _buildTextField(
                          controller: _emailController,
                          hintText: 'jane@example.com',
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Phone Number'),
                        _buildTextField(
                          controller: _phoneController,
                          hintText: '+60 12-345 6789',
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
                        _buildLabel('Password'),
                        _buildTextField(
                          controller: _passwordController,
                          isPassword: true,
                          hintText: widget.userId == null
                              ? 'Min 6 characters'
                              : 'Leave empty to keep unchanged',
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Retype Password'),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          isPassword: true,
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Date Joined'),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd MMM yyyy').format(_dateJoined),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              if (_emailController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter an email address first',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await FirebaseAuth.instance
                                    .sendPasswordResetEmail(
                                      email: _emailController.text.trim(),
                                    );
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Email sent! Check Inbox & Spam folder for ${_emailController.text}',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to send reset email: $e',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.email_outlined),
                            label: const Text('Send Password Reset Email'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.black),
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ),
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
                                  onPressed: _isSaving ? null : _saveUser,
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
