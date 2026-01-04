import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:blossom_app/features/staff/screens/booking/appointment_details_screen.dart';

class NotificationItem {
  final String id;
  final String type;
  final String time;
  final Widget content;
  final bool hasActions;
  bool isExpanded;

  NotificationItem({
    required this.id,
    required this.type,
    required this.time,
    required this.content,
    this.hasActions = false,
    this.isExpanded = false,
  });
}

class StaffNotificationsScreen extends StatefulWidget {
  const StaffNotificationsScreen({super.key});

  @override
  State<StaffNotificationsScreen> createState() =>
      _StaffNotificationsScreenState();
}

class _StaffNotificationsScreenState extends State<StaffNotificationsScreen> {
  Future<void> _deleteNotification(String id) async {
    await FirebaseDatabase.instance.ref('notifications/staff/$id').remove();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
    }
  }

  String _formatTime(dynamic ts) {
    try {
      final ms = ts is int ? ts : int.tryParse(ts.toString()) ?? 0;
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return DateFormat('d MMM yyyy, h:mm a').format(dt);
    } catch (_) {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Beige background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('notifications/staff').onValue,
        builder: (context, snapshot) {
          final data = snapshot.data?.snapshot.value;
          if (data == null) {
            return const Center(
              child: Text(
                'No notifications',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          final map = Map<dynamic, dynamic>.from(data as Map);
          final items =
              map.entries.map((e) {
                final m = Map<String, dynamic>.from(e.value as Map);
                m['id'] = e.key.toString();
                return m;
              }).toList()..sort((a, b) {
                final ta = a['timestamp'] ?? 0;
                final tb = b['timestamp'] ?? 0;
                return (tb is int ? tb : 0).compareTo(ta is int ? ta : 0);
              });
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 15),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildNotificationCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return InkWell(
      onTap: () async {
        final bookingId = notification['bookingId']?.toString();
        if (bookingId == null || bookingId.isEmpty) return;
        try {
          final snap = await FirebaseDatabase.instance
              .ref('bookings/$bookingId')
              .get();
          if (!snap.exists) return;
          final booking = Map<String, dynamic>.from(snap.value as Map);
          booking['id'] = bookingId;
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AppointmentDetailsScreen(booking: booking),
            ),
          );
        } catch (_) {}
      },
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: const Color(0xFF4E4E4E),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (notification['type']?.toString() ?? 'Notification')
                                .replaceAll('_', ' ')
                                .split(' ')
                                .map(
                                  (w) => w.isEmpty
                                      ? ''
                                      : '${w[0].toUpperCase()}${w.substring(1)}',
                                )
                                .join(' '),
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _formatTime(notification['timestamp']),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () =>
                            _deleteNotification(notification['id'] as String),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    notification['message']?.toString() ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
