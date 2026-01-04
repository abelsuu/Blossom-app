import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'add_staff_screen.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  bool _isAddingStaff = false;
  String? _editingStaffId;
  Map<String, dynamic>? _editingStaffData;

  @override
  Widget build(BuildContext context) {
    if (_isAddingStaff) {
      return AddStaffScreen(
        staffId: _editingStaffId,
        initialData: _editingStaffData,
        onSave: () {
          setState(() {
            _isAddingStaff = false;
            _editingStaffId = null;
            _editingStaffData = null;
          });
        },
        onCancel: () {
          setState(() {
            _isAddingStaff = false;
            _editingStaffId = null;
            _editingStaffData = null;
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
                  // Profile Dropdown
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

          // Staffs Information Table Card
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Staffs Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D5343),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7CCC8), // Beige header background
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Role',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Contact',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Actions',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Table Rows
                  Expanded(
                    child: StreamBuilder<DatabaseEvent>(
                      stream: FirebaseDatabase.instance.ref('staffs').onValue,
                      builder: (context, staffSnapshot) {
                        return StreamBuilder<DatabaseEvent>(
                          stream: FirebaseDatabase.instance
                              .ref('users')
                              .onValue,
                          builder: (context, usersSnapshot) {
                            if (staffSnapshot.hasError ||
                                usersSnapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error: ${staffSnapshot.error ?? usersSnapshot.error}',
                                ),
                              );
                            }
                            if (staffSnapshot.connectionState ==
                                    ConnectionState.waiting ||
                                usersSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF5D5343),
                                ),
                              );
                            }

                            final staffData =
                                staffSnapshot.data?.snapshot.value;
                            final usersData =
                                usersSnapshot.data?.snapshot.value;

                            final List<Map<String, dynamic>> finalStaffList =
                                [];
                            final List<String> finalKeys = [];
                            final Set<String> existingEmails = {};

                            // 1. Process Real Staff
                            if (staffData is Map) {
                              staffData.forEach((key, value) {
                                final m = Map<String, dynamic>.from(
                                  value as Map,
                                );
                                final email = (m['email'] ?? '')
                                    .toString()
                                    .trim()
                                    .toLowerCase();
                                if (email.startsWith('staff')) {
                                  finalStaffList.add(m);
                                  finalKeys.add(key.toString());
                                  existingEmails.add(email);
                                }
                              });
                            }

                            // 2. Process Users with blossom.my domain
                            if (usersData is Map) {
                              usersData.forEach((key, value) {
                                final m = Map<String, dynamic>.from(
                                  value as Map,
                                );
                                final profile = m['profile'];
                                if (profile is Map) {
                                  final p = Map<String, dynamic>.from(profile);
                                  final email = (p['email'] ?? '')
                                      .toString()
                                      .trim();
                                  final emailLower = email.toLowerCase();

                                  if (emailLower.startsWith('staff')) {
                                    // Only add if not already in staff list
                                    if (!existingEmails.contains(emailLower)) {
                                      final firstName = (p['firstName'] ?? '')
                                          .toString();
                                      final lastName = (p['lastName'] ?? '')
                                          .toString();
                                      final name = '$firstName $lastName'
                                          .trim();
                                      final phone =
                                          (p['phoneNumber'] ??
                                                  p['phone'] ??
                                                  '-')
                                              .toString();

                                      finalStaffList.add({
                                        'name': name.isEmpty ? 'Unknown' : name,
                                        'email': email,
                                        'role': 'User (Unverified)',
                                        'status': 'Active',
                                        'contact': phone,
                                        'isVirtual':
                                            true, // Flag to identify virtual staff
                                        'uid': key, // Original User ID
                                      });
                                      finalKeys.add(key.toString());
                                      existingEmails.add(emailLower);
                                    }
                                  }
                                }
                              });
                            }

                            if (finalStaffList.isEmpty) {
                              return const Center(
                                child: Text('No staff members found.'),
                              );
                            }

                            return ListView.separated(
                              itemCount: finalStaffList.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              itemBuilder: (context, index) {
                                return _buildStaffRow(
                                  finalKeys[index],
                                  finalStaffList[index],
                                );
                              },
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

          const SizedBox(height: 24),

          // Add Staff Button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _isAddingStaff = true;
                });
              },
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 16, color: Colors.black),
              ),
              label: const Text(
                'Add Staff Information',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'on leave':
        return Colors.amber;
      case 'resigned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _deleteStaff(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff'),
        content: const Text(
          'Are you sure you want to delete this staff member?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseDatabase.instance.ref('staffs/$docId').remove();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting staff: $e')));
        }
      }
    }
  }

  Widget _buildStaffRow(String docId, Map<String, dynamic> staffData) {
    final name = staffData['name'] ?? 'Unknown';
    final role = staffData['role'] ?? '-';
    final status = staffData['status'] ?? 'Active';
    final contact = staffData['contact'] ?? '-';
    final statusColor = _getStatusColor(status);
    final isVirtual = staffData['isVirtual'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(name)),
          Expanded(flex: 2, child: Text(role)),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(contact)),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Color(0xFF5D5343),
                  ),
                  onPressed: () {
                    if (isVirtual) {
                      // Promote to real staff
                      setState(() {
                        _editingStaffId = null; // New staff entry
                        _editingStaffData = {
                          'name': name,
                          'email': staffData['email'],
                          'role': 'Staff',
                          'status': 'Active',
                          'contact': contact,
                        };
                        _isAddingStaff = true;
                      });
                    } else {
                      setState(() {
                        _editingStaffId = docId;
                        _editingStaffData = staffData;
                        _isAddingStaff = true;
                      });
                    }
                  },
                ),
                if (!isVirtual)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outlined,
                      size: 20,
                      color: Colors.red,
                    ),
                    onPressed: () => _deleteStaff(docId),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
