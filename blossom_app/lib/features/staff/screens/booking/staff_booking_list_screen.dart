import 'package:flutter/material.dart';
import 'package:blossom_app/features/staff/services/staff_service.dart';
import 'package:blossom_app/features/staff/screens/booking/appointment_details_screen.dart';
import 'package:intl/intl.dart';

class StaffBookingListScreen extends StatefulWidget {
  final bool isTab;

  const StaffBookingListScreen({super.key, this.isTab = false});

  @override
  State<StaffBookingListScreen> createState() => _StaffBookingListScreenState();
}

class _StaffBookingListScreenState extends State<StaffBookingListScreen> {
  String _sortOrder = 'newest'; // 'newest' or 'oldest'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Beige
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Booking List',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.sort, color: Colors.black),
                        tooltip: 'Sort Bookings',
                        onSelected: (value) {
                          setState(() {
                            _sortOrder = value;
                          });
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'newest',
                            child: Row(
                              children: [
                                Icon(Icons.arrow_downward, size: 18),
                                SizedBox(width: 8),
                                Text('Newest First'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'oldest',
                            child: Row(
                              children: [
                                Icon(Icons.arrow_upward, size: 18),
                                SizedBox(width: 8),
                                Text('Oldest First'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!widget.isTab)
                        IconButton(
                          icon: const Icon(
                            Icons.reply,
                            size: 30,
                            color: Colors.black,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.black54, thickness: 1),
              const SizedBox(height: 10),

              // Booking List
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: StaffService.getAllBookingsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading bookings'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var bookings = snapshot.data ?? [];

                    // Sort bookings
                    bookings.sort((a, b) {
                      try {
                        DateTime dtA = _parseDateTime(a['date'], a['time']);
                        DateTime dtB = _parseDateTime(b['date'], b['time']);
                        
                        if (_sortOrder == 'newest') {
                          return dtB.compareTo(dtA);
                        } else {
                          return dtA.compareTo(dtB);
                        }
                      } catch (e) {
                        return 0;
                      }
                    });

                    if (bookings.isEmpty) {
                      return const Center(
                        child: Text(
                          'No bookings found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return _buildBookingCard(context, booking);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _parseDateTime(String? dateStr, String? timeStr) {
    final now = DateTime.now();
    if (dateStr == null) return now;
    
    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateStr);
      
      int hour = 0;
      int minute = 0;
      
      if (timeStr != null && timeStr.isNotEmpty) {
        // Try parsing different time formats
        try {
           // Try H:mm
           final parts = timeStr.split(':');
           if (parts.length == 2) {
             hour = int.parse(parts[0]);
             minute = int.parse(parts[1]);
           }
        } catch (_) {
          // If simple split fails, try parsing with DateFormat if needed
          // But assuming standard H:mm or similar from earlier code context
        }
      }
      
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      return now;
    }
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> booking) {
    final date = booking['date'] ?? 'Unknown Date';
    final time = booking['time'] ?? 'Unknown Time';
    final customerName = booking['userName'] ?? 'Unknown Customer';
    final service = booking['request'] ?? 'Unknown Service';
    final status = booking['status'] ?? 'pending';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
    }

    // Format date for display if possible
    String displayDate = date;
    try {
      final parsedDate = DateFormat('yyyy-MM-dd').parse(date);
      displayDate = DateFormat('MMM d, yyyy').format(parsedDate);
    } catch (e) {
      // Keep original string if parsing fails
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AppointmentDetailsScreen(booking: booking),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    displayDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF556B2F), // Olive Green
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(
                    time,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(
                    customerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.spa, size: 16, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(
                    service,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
