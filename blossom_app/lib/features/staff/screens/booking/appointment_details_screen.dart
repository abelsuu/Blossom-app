import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:blossom_app/features/staff/services/staff_service.dart';
import 'package:blossom_app/features/customer/services/catalog_service.dart';
import 'package:blossom_app/common/widgets/multi_select_dropdown.dart';
import 'package:blossom_app/common/widgets/text_input_dialog.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const AppointmentDetailsScreen({super.key, required this.booking});

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  late TextEditingController _noteController;
  late String _currentStatus;
  List<String> _selectedServices = [];

  final List<String> _hardcodedServices = [
    'Body Massage',
    'Milk Bath',
    'Facial',
    'Manicure',
    'Pedicure',
    'Hair Treatment',
  ];

  // Hardcoded for now as they are not in booking data yet
  final String _customerImage =
      'https://images.unsplash.com/photo-1580489944761-15a19d654956?q=80&w=200&auto=format&fit=crop';

  @override
  void initState() {
    super.initState();
    _currentStatus = _normalizeStatus(widget.booking['status'] ?? 'pending');

    // Initialize services
    final List<dynamic>? services =
        widget.booking['services'] as List<dynamic>?;

    if (services != null && services.isNotEmpty) {
      for (final s in services) {
        if (s is String) {
          _selectedServices.add(s);
        }
      }
    } else {
      // Fallback to legacy single service fields
      final service = widget.booking['request'] ?? widget.booking['service'];
      if (service is String && service.isNotEmpty) {
        _selectedServices.add(service);
      }
    }
  }

  String _normalizeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'in progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String? newValue) async {
    if (newValue == null) return;
    setState(() {
      _currentStatus = newValue;
    });
    await StaffService.updateBookingStatus(widget.booking['id'], newValue);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status updated to $newValue')));
    }
  }

  Future<void> _saveServices() async {
    await StaffService.updateBookingServices(
      widget.booking['id'],
      _selectedServices,
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Services updated')));
    }
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => TextInputDialog(
        title: 'Add Note',
        hintText: 'Enter note here...',
        confirmText: 'Add',
        onConfirm: (text) async {
          await StaffService.addBookingNote(
            widget.booking['id'],
            text,
            customerName: widget.booking['userName'],
          );
        },
      ),
    );
  }

  void _showEditNoteDialog(String noteId, String currentContent) {
    showDialog(
      context: context,
      builder: (dialogContext) => TextInputDialog(
        title: 'Edit Note',
        initialValue: currentContent,
        hintText: 'Enter note here...',
        confirmText: 'Save',
        onConfirm: (text) async {
          await StaffService.updateBookingNote(
            widget.booking['id'],
            noteId,
            text,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.booking['date'] ?? '';
    final timeStr = widget.booking['time'] ?? '';

    // Parse date for display
    String day = '';
    String monthYear = '';
    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateStr);
      day = DateFormat('d').format(date);
      monthYear = DateFormat('MMM, yyyy').format(date);
    } catch (e) {
      day = dateStr.split('-').last;
      monthYear = dateStr;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Beige background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Appointment Details',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appointment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37), // Gold/Mustard
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          day,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          monthYear,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Customer Info
            StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance
                  .ref('users/${widget.booking['userId']}')
                  .onValue,
              builder: (context, snapshot) {
                final rootData =
                    snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
                final profile = rootData?['profile'] as Map<dynamic, dynamic>?;

                final name = (() {
                  final fn = profile?['firstName']?.toString() ?? '';
                  final ln = profile?['lastName']?.toString() ?? '';
                  final full = [fn, ln].where((s) => s.isNotEmpty).join(' ');
                  if (full.isNotEmpty) return full;
                  return (rootData?['name']?.toString() ??
                      widget.booking['userName']?.toString() ??
                      'Unknown Customer');
                })();

                final phone =
                    (profile?['phone']?.toString() ??
                    rootData?['phone']?.toString() ??
                    '');
                final email =
                    (rootData?['email']?.toString() ??
                    profile?['email']?.toString() ??
                    '');

                // Decode profile picture
                final photoBase64 = profile?['photoBase64']?.toString();
                Uint8List? photoBytes;
                if (photoBase64 != null && photoBase64.isNotEmpty) {
                  try {
                    photoBytes = base64Decode(photoBase64);
                  } catch (_) {
                    photoBytes = null;
                  }
                }

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: photoBytes != null
                          ? MemoryImage(photoBytes)
                          : NetworkImage(_customerImage) as ImageProvider,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (phone.isNotEmpty)
                            Text(
                              'Phone: $phone',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          if (email.isNotEmpty)
                            Text(
                              'Email: $email',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (phone.isNotEmpty)
                                ElevatedButton(
                                  onPressed: () {
                                    launchUrlString('tel:$phone');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD4AF37),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                  ),
                                  child: const Text('Call Customer'),
                                ),
                              const SizedBox(width: 10),
                              if (email.isNotEmpty)
                                ElevatedButton(
                                  onPressed: () {
                                    final subject = Uri.encodeComponent(
                                      'Booking Confirmation',
                                    );
                                    final body = Uri.encodeComponent(
                                      'Dear $name,\n\nYour booking has been confirmed.\n\nBest regards,\nBlossom',
                                    );
                                    launchUrlString(
                                      'mailto:$email?subject=$subject&body=$body',
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5D5343),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                  ),
                                  child: const Text('Email Customer'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Status Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Text(
                    'Status: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currentStatus,
                        isExpanded: true,
                        items:
                            [
                              'Pending',
                              'Confirmed',
                              'In Progress',
                              'Completed',
                              'Cancelled',
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    color: value == 'Cancelled'
                                        ? Colors.red
                                        : Colors.black,
                                  ),
                                ),
                              );
                            }).toList(),
                        onChanged: _updateStatus,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_currentStatus == 'Pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await StaffService.updateBookingStatus(
                      widget.booking['id'],
                      'Confirmed',
                    );
                    try {
                      final uid = widget.booking['userId'];
                      if (uid != null) {
                        String friendlyDate =
                            widget.booking['date']?.toString() ?? '';
                        try {
                          final parsed = DateFormat(
                            'yyyy-MM-dd',
                          ).parse(friendlyDate);
                          friendlyDate = DateFormat(
                            'EEEE, d MMMM',
                          ).format(parsed);
                        } catch (_) {
                          // Keep raw string if parsing fails
                        }
                        final friendlyTime =
                            widget.booking['time']?.toString() ?? '';
                        await FirebaseDatabase.instance
                            .ref('notifications/$uid')
                            .push()
                            .set({
                              'message':
                                  'Great news! Your appointment on $friendlyDate at $friendlyTime is confirmed. Tap to see your appointment summary.',
                              'timestamp': ServerValue.timestamp,
                              'type': 'booking_confirmed',
                              'bookingId': widget.booking['id'],
                              'date': widget.booking['date'],
                              'time': widget.booking['time'],
                            });
                      }
                    } catch (_) {}
                    if (mounted) {
                      setState(() {
                        _currentStatus = 'Confirmed';
                      });
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Booking confirmed')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D5343),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm Booking'),
                ),
              ),
            const SizedBox(height: 10),

            // Services Info
            const Text(
              'Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: CatalogService.getAllServicesStreamWithFallback(),
              builder: (context, snapshot) {
                final servicesData = snapshot.data ?? [];
                List<String> allTitles = servicesData
                    .map((s) => s['title'])
                    .whereType<String>()
                    .where((t) => t.trim().isNotEmpty)
                    .toSet()
                    .toList();

                // Fallback if catalog is empty or offline
                if (allTitles.isEmpty) {
                  allTitles = _hardcodedServices;
                }

                // Ensure currently selected services are in the list if they are custom/old
                for (final s in _selectedServices) {
                  if (!allTitles.contains(s)) {
                    allTitles.add(s);
                  }
                }

                return MultiSelectDropdownWithChips(
                  allItems: allTitles,
                  selectedItems: _selectedServices,
                  onChanged: (list) {
                    setState(() {
                      _selectedServices = list;
                    });
                    _saveServices();
                  },
                  hint: 'Select Services',
                  maxSelection: 3,
                );
              },
            ),
            const SizedBox(height: 30),

            // Notes Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFFD4AF37)),
                  onPressed: _showAddNoteDialog,
                ),
              ],
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: StaffService.getBookingNotesStream(widget.booking['id']),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error loading notes');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final notes = snapshot.data ?? [];
                if (notes.isEmpty) {
                  return const Text('No notes yet.');
                }
                return Column(
                  children: notes.map((note) {
                    final noteId = note['id'];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(note['content'] ?? ''),
                        subtitle: Text(
                          DateFormat('MMM d, yyyy h:mm a').format(
                            DateTime.fromMillisecondsSinceEpoch(
                              note['timestamp'] ?? 0,
                            ),
                          ),
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: PopupMenuButton(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditNoteDialog(noteId, note['content']);
                            } else if (value == 'delete') {
                              StaffService.deleteBookingNote(
                                widget.booking['id'],
                                noteId,
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
