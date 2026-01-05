import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'add_user_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool _isAddingUser = false;
  String? _editingUserId;
  Map<String, dynamic>? _editingUserData;

  @override
  Widget build(BuildContext context) {
    if (_isAddingUser) {
      return AddUserScreen(
        userId: _editingUserId,
        initialData: _editingUserData,
        onSave: () {
          setState(() {
            _isAddingUser = false;
            _editingUserId = null;
            _editingUserData = null;
          });
        },
        onCancel: () {
          setState(() {
            _isAddingUser = false;
            _editingUserId = null;
            _editingUserData = null;
          });
        },
      );
    }

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
                    'Users Management',
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
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isAddingUser = true;
                        _editingUserId = null;
                        _editingUserData = null;
                      });
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D5343),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
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

          const SizedBox(height: 24),

          // Users Table
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'NAME',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'EMAIL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'PHONE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'JOINED DATE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Rows
                  Expanded(
                    child: StreamBuilder<DatabaseEvent>(
                      stream: FirebaseDatabase.instance.ref('users').onValue,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF5D5343),
                            ),
                          );
                        }
                        final data = snapshot.data?.snapshot.value;
                        if (data == null || (data is Map && data.isEmpty)) {
                          return const Center(child: Text('No users found.'));
                        }
                        final List<Map<String, dynamic>> rows = [];
                        if (data is Map) {
                          data.forEach((uid, value) {
                            if (value is Map) {
                              final m = Map<String, dynamic>.from(value);
                              final profile = m['profile'];
                              String name = 'Unknown';
                              String email = '-';
                              String phone = '-';
                              String dateStr = '-';
                              if (profile is Map) {
                                final p = Map<String, dynamic>.from(profile);
                                final firstName = (p['firstName'] ?? '')
                                    .toString()
                                    .trim();
                                final lastName = (p['lastName'] ?? '')
                                    .toString()
                                    .trim();
                                final combined = [
                                  firstName,
                                  lastName,
                                ].where((s) => s.isNotEmpty).join(' ');
                                name = combined.isNotEmpty
                                    ? combined
                                    : 'Unknown';
                                email = (p['email'] ?? '-').toString();
                                phone = (p['phoneNumber'] ?? p['phone'] ?? '-')
                                    .toString();
                                final createdAt = p['createdAt'];
                                if (createdAt is int) {
                                  dateStr = DateFormat('dd MMM yyyy').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      createdAt,
                                    ),
                                  );
                                } else if (createdAt is String &&
                                    createdAt.isNotEmpty) {
                                  dateStr = createdAt;
                                }
                              }
                              final emailLower = email
                                  .toString()
                                  .trim()
                                  .toLowerCase();
                              final isStaffAccount = emailLower.startsWith(
                                'staff',
                              );

                              String? photoBase64;
                              if (profile is Map) {
                                photoBase64 = profile['photoBase64']
                                    ?.toString();
                              }

                              // Show all users, even if they have a staff domain
                              // This allows admins to see staff who signed up as customers
                              rows.add({
                                'uid': uid,
                                'name': name,
                                'email': email,
                                'phone': phone,
                                'date': dateStr,
                                'photoBase64': photoBase64,
                                'isStaff':
                                    isStaffAccount, // Optional: for UI indication
                              });
                            }
                          });
                        }
                        return ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            return _buildUserRow(
                              row['uid'] as String,
                              row['name'] as String,
                              row['email'] as String,
                              row['phone'] as String,
                              row['date'] as String,
                              row['photoBase64'] as String?,
                            );
                          },
                        );
                      },
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

  Widget _buildUserRow(
    String uid,
    String name,
    String email,
    String phone,
    String date,
    String? photoBase64,
  ) {
    Uint8List? photoBytes;
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      try {
        photoBytes = base64Decode(photoBase64);
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              image: photoBytes != null
                  ? DecorationImage(
                      image: MemoryImage(photoBytes),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photoBytes == null
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(email, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            flex: 2,
            child: Text(phone, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            flex: 2,
            child: Text(date, style: const TextStyle(color: Colors.grey)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: Color(0xFF5D5343),
                  size: 20,
                ),
                onPressed: () => _startEditUser(uid),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _deleteUser(uid),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startEditUser(String uid) {
    FirebaseDatabase.instance.ref('users/$uid/profile').get().then((snapshot) {
      if (snapshot.exists && snapshot.value != null) {
        setState(() {
          _editingUserId = uid;
          _editingUserData = Map<String, dynamic>.from(snapshot.value as Map);
          _isAddingUser = true;
        });
      }
    });
  }

  void _deleteUser(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text(
          'Are you sure you want to delete this user? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              FirebaseDatabase.instance.ref('users/$uid').remove();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
