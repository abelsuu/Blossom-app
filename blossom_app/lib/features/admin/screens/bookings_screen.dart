import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:blossom_app/common/widgets/multi_select_dropdown.dart';
import 'package:blossom_app/features/customer/services/catalog_service.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  bool _isCalendarView = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final DatabaseReference _db = FirebaseDatabase.instance.ref('bookings');

  void _showBookingDialog({String? docId, Map<String, dynamic>? data}) {
    final nameController = TextEditingController(
      text: data?['customerName'] ?? data?['userName'] ?? '',
    );

    // Initialize selected services
    List<String> selectedServices = [];
    if (data != null) {
      if (data['services'] is List) {
        selectedServices = List<String>.from(
          (data['services'] as List).map((e) => e.toString()),
        );
      } else if (data['service'] is String &&
          (data['service'] as String).isNotEmpty) {
        selectedServices = [data['service'] as String];
      } else if (data['request'] is String &&
          (data['request'] as String).isNotEmpty) {
        selectedServices = [data['request'] as String];
      }
    }

    final staffController = TextEditingController(text: data?['staff'] ?? '');

    String dateStr = '';
    String timeStr = '';
    if (data != null) {
      if (data['date'] != null) {
        dateStr = (data['date'] as String);
      }
      if (data['time'] != null) {
        timeStr = (data['time'] as String);
      }
    }

    final dateController = TextEditingController(text: dateStr);
    final timeController = TextEditingController(text: timeStr);

    // Helper for Date Picker
    Future<void> pickDate() async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF5D5343), // Header background color
                onPrimary: Colors.white, // Header text color
                onSurface: Color(0xFF5D5343), // Body text color
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF5D5343), // Button text color
                ),
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        // Format: YYYY-MM-DD
        final formatted =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        setState(() {
          dateController.text = formatted;
        });
      }
    }

    // Helper for Time Picker
    Future<void> pickTime() async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
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
      if (picked != null) {
        if (!mounted) return;
        // Format: HH:MM AM/PM
        final localizations = MaterialLocalizations.of(context);
        final formatted = localizations.formatTimeOfDay(
          picked,
          alwaysUse24HourFormat: false,
        );
        setState(() {
          timeController.text = formatted;
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: SingleChildScrollView(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Main Card Background
                  Container(
                    width: 400,
                    margin: const EdgeInsets.only(top: 40),
                    padding: const EdgeInsets.fromLTRB(32, 70, 32, 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1), // Light Beige
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          docId == null
                              ? 'New Appointment'
                              : 'Edit Appointment',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D5343),
                            fontFamily: 'Serif', // Elegant touch
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fill in the details below',
                          style: TextStyle(
                            color: const Color(
                              0xFF5D5343,
                            ).withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Fields
                        _buildCreativeTextField(
                          controller: nameController,
                          label: 'Customer Name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),

                        // Service Dropdown
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream:
                              CatalogService.getAllServicesStreamWithFallback(),
                          builder: (context, snapshot) {
                            final servicesData = snapshot.data ?? [];
                            List<String> allTitles = servicesData
                                .map((s) => s['title'])
                                .whereType<String>()
                                .where((t) => t.trim().isNotEmpty)
                                .toSet()
                                .toList();

                            // Fallback hardcoded list if empty
                            if (allTitles.isEmpty) {
                              allTitles = [
                                'Body Massage',
                                'Milk Bath',
                                'Facial',
                                'Manicure',
                                'Pedicure',
                                'Hair Treatment',
                              ];
                            }

                            // Ensure currently selected services are in the list
                            for (final s in selectedServices) {
                              if (!allTitles.contains(s)) {
                                allTitles.add(s);
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 12,
                                    bottom: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.spa_outlined,
                                        size: 16,
                                        color: Color(0xFFD7CCC8),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Services',
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                MultiSelectDropdownWithChips(
                                  allItems: allTitles,
                                  selectedItems: selectedServices,
                                  hint: 'Select Services',
                                  onChanged: (list) {
                                    setState(() {
                                      selectedServices = list;
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Staff Dropdown (Dynamic Availability)
                        StreamBuilder<DatabaseEvent>(
                          stream: FirebaseDatabase.instance
                              .ref('staffs')
                              .onValue,
                          builder: (context, staffSnapshot) {
                            // 1. Get All Staff
                            final List<String> allStaffNames = [];
                            if (staffSnapshot.hasData &&
                                staffSnapshot.data!.snapshot.value != null) {
                              final data =
                                  staffSnapshot.data!.snapshot.value as Map;
                              data.forEach((key, value) {
                                if (value is Map && value['name'] != null) {
                                  allStaffNames.add(value['name'].toString());
                                }
                              });
                            }

                            return StreamBuilder<DatabaseEvent>(
                              stream: FirebaseDatabase.instance
                                  .ref('bookings')
                                  .onValue,
                              builder: (context, bookingSnapshot) {
                                // 2. Identify Busy Staff
                                final Set<String> busyStaff = {};
                                if (bookingSnapshot.hasData &&
                                    bookingSnapshot.data!.snapshot.value !=
                                        null) {
                                  final bData =
                                      bookingSnapshot.data!.snapshot.value
                                          as Map;
                                  bData.forEach((key, value) {
                                    // Exclude current booking if editing
                                    if (docId != null && key == docId) return;

                                    if (value is Map) {
                                      final bDate = value['date'];
                                      final bTime = value['time'];
                                      final bStaff = value['staff'];

                                      // Check conflict
                                      if (bDate == dateController.text &&
                                          bTime == timeController.text &&
                                          bStaff != null) {
                                        busyStaff.add(bStaff.toString());
                                      }
                                    }
                                  });
                                }

                                // 3. Filter Available Staff
                                final availableStaff = allStaffNames
                                    .where((name) => !busyStaff.contains(name))
                                    .toList();

                                // Ensure current selection is in list (if valid)
                                if (staffController.text.isNotEmpty &&
                                    !availableStaff.contains(
                                      staffController.text,
                                    )) {
                                  availableStaff.add(staffController.text);
                                }

                                final isDateSelected =
                                    dateController.text.isNotEmpty;
                                final isTimeSelected =
                                    timeController.text.isNotEmpty;
                                final isEnabled =
                                    isDateSelected && isTimeSelected;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF5D5343,
                                        ).withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 4,
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButtonFormField<String>(
                                      value: staffController.text.isEmpty
                                          ? null
                                          : staffController.text,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        prefixIcon: Icon(
                                          Icons.badge_outlined,
                                          color: Color(0xFFD7CCC8),
                                        ),
                                        labelText: 'Staff Preference',
                                        labelStyle: TextStyle(
                                          color: Colors.grey,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      hint: Text(
                                        !isEnabled
                                            ? 'Select Date & Time first'
                                            : (availableStaff.isEmpty
                                                  ? 'No staff available'
                                                  : 'Select Staff'),
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 14,
                                        ),
                                      ),
                                      items: isEnabled
                                          ? availableStaff.map((staff) {
                                              return DropdownMenuItem(
                                                value: staff,
                                                child: Text(
                                                  staff,
                                                  style: const TextStyle(
                                                    color: Color(0xFF5D5343),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              );
                                            }).toList()
                                          : [],
                                      onChanged: isEnabled
                                          ? (value) {
                                              if (value != null) {
                                                setState(() {
                                                  staffController.text = value;
                                                });
                                              }
                                            }
                                          : null,
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        color: Color(0xFFD7CCC8),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date & Time Row
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: pickDate,
                                child: AbsorbPointer(
                                  child: _buildCreativeTextField(
                                    controller: dateController,
                                    label: 'Date',
                                    icon: Icons.calendar_today_outlined,
                                    isReadOnly: true,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: pickTime,
                                child: AbsorbPointer(
                                  child: _buildCreativeTextField(
                                    controller: timeController,
                                    label: 'Time',
                                    icon: Icons.access_time_outlined,
                                    isReadOnly: true,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  foregroundColor: const Color(0xFF5D5343),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (nameController.text.isEmpty ||
                                      selectedServices.isEmpty ||
                                      dateController.text.isEmpty ||
                                      timeController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please fill in all fields (Name, Service, Date, Time)',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  final Map<String, dynamic> bookingData = {
                                    'customerName': nameController.text.trim(),
                                    'services': selectedServices,
                                    'staff': staffController.text.trim(),
                                    'date': dateController.text.trim(),
                                    'time': timeController.text.trim(),
                                    'status': (data?['status'] ?? 'Pending'),
                                    'updatedAt': ServerValue.timestamp,
                                  };

                                  if (docId == null) {
                                    bookingData['timestamp'] =
                                        ServerValue.timestamp;
                                    final newRef = _db.push();
                                    await newRef.set(bookingData);
                                  } else {
                                    await _db.child(docId).update(bookingData);
                                  }

                                  if (context.mounted) Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5D5343),
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: const Color(
                                    0xFF5D5343,
                                  ).withValues(alpha: 0.4),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  docId == null
                                      ? 'Create Booking'
                                      : 'Save Changes',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Floating Header Icon
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D5343),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFF8E1),
                          width: 6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreativeTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isReadOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D5343).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        style: const TextStyle(
          color: Color(0xFF5D5343),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: const Color(0xFFD7CCC8)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteBooking(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text(
          'Are you sure you want to delete this appointment?',
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
      await _db.child(docId).remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointment',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D5343),
                    ),
                  ),
                  Text(
                    'Welcome back Admin 1',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF5D5343)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isCalendarView = false;
                            });
                          },
                          icon: Icon(
                            Icons.list,
                            color: !_isCalendarView
                                ? const Color(0xFF5D5343)
                                : Colors.grey,
                          ),
                          tooltip: 'List View',
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: const Color(0xFF5D5343),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isCalendarView = true;
                            });
                          },
                          icon: Icon(
                            Icons.calendar_month,
                            color: _isCalendarView
                                ? const Color(0xFF5D5343)
                                : Colors.grey,
                          ),
                          tooltip: 'Calendar View',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showBookingDialog(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add New Appointment'),
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
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
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
              child: StreamBuilder<DatabaseEvent>(
                stream: _db.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5D5343),
                      ),
                    );
                  }
                  final data = snapshot.data?.snapshot.value;
                  final List<Map<String, dynamic>> bookings = [];
                  final List<String> keys = [];
                  if (data is Map) {
                    data.forEach((key, value) {
                      final m = Map<String, dynamic>.from(value as Map);
                      bookings.add(m);
                      keys.add(key as String);
                    });
                  }
                  if (bookings.isEmpty) {
                    return const Center(child: Text('No appointments found.'));
                  }
                  final indexed = List.generate(bookings.length, (i) {
                    final m = bookings[i];
                    m['id'] = keys[i];
                    return m;
                  });
                  indexed.sort((a, b) {
                    final ta = a['timestamp'] ?? 0;
                    final tb = b['timestamp'] ?? 0;
                    return (tb as int).compareTo(ta as int);
                  });
                  if (_isCalendarView) {
                    return _buildCalendarView(indexed);
                  }
                  return ListView.separated(
                    itemCount: indexed.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final booking = indexed[index];
                      final name =
                          booking['customerName'] ??
                          booking['userName'] ??
                          'Unknown';
                      final services = booking['services'];
                      final serviceStr = services is List
                          ? services.whereType<String>().join(', ')
                          : (booking['service'] ?? '');
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFEEE6D3),
                          child: Text(
                            name.toString().isNotEmpty
                                ? name.toString()[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Color(0xFF5D5343),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          name.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '$serviceStr - ${booking['date']} ${booking['time'] ?? ''}\nStaff: ${booking['staff'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (booking['status'] ?? 'Pending').toString(),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFF5D5343),
                                size: 20,
                              ),
                              onPressed: () => _showBookingDialog(
                                docId: booking['id'].toString(),
                                data: booking,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () =>
                                  _deleteBooking(booking['id'].toString()),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(List<Map<String, dynamic>> bookings) {
    final Map<DateTime, List<Map<String, dynamic>>> events = {};
    for (var data in bookings) {
      final dateStr = data['date'] as String?;
      if (dateStr != null) {
        try {
          final date = DateTime.parse(dateStr);
          final normalizedDate = DateTime(date.year, date.month, date.day);
          events.putIfAbsent(normalizedDate, () => []);
          events[normalizedDate]!.add(data);
        } catch (_) {}
      }
    }

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            return events[normalizedDay] ?? [];
          },
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Color(0xFFEEE6D3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Color(0xFF5D5343),
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Color(0xFF5D5343),
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _selectedDay == null
              ? const Center(child: Text('Select a day to view appointments'))
              : Builder(
                  builder: (context) {
                    final normalizedSelectedDay = DateTime(
                      _selectedDay!.year,
                      _selectedDay!.month,
                      _selectedDay!.day,
                    );
                    final selectedEvents = events[normalizedSelectedDay] ?? [];

                    if (selectedEvents.isEmpty) {
                      return const Center(
                        child: Text('No appointments for this day'),
                      );
                    }

                    return ListView.separated(
                      itemCount: selectedEvents.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final booking = selectedEvents[index];
                        final name =
                            booking['customerName'] ??
                            booking['userName'] ??
                            'Unknown';
                        final services = booking['services'];
                        final serviceStr = services is List
                            ? services.whereType<String>().join(', ')
                            : (booking['service'] ?? '');
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFEEE6D3),
                            child: Text(
                              name.toString().isNotEmpty
                                  ? name.toString()[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Color(0xFF5D5343),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            name.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '$serviceStr - ${booking['date']} ${booking['time'] ?? ''}\nStaff: ${booking['staff'] ?? ''}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  (booking['status'] ?? 'Pending').toString(),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF5D5343),
                                  size: 20,
                                ),
                                onPressed: () => _showBookingDialog(
                                  docId: booking['id'] as String?,
                                  data: booking,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _deleteBooking(booking['id'] as String),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
