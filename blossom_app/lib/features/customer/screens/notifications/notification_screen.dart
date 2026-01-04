import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Beige background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3142)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3142),
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, userSnapshot) {
          final user = userSnapshot.data;
          if (user == null) {
            return const Center(
              child: Text(
                'Login to see notifications',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance
                .ref('notifications/${user.uid}')
                .onValue,
            builder: (context, snapshot) {
              final data = snapshot.data?.snapshot.value;
              if (data == null) {
                return const Center(
                  child: Text(
                    'No notifications',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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
                padding: const EdgeInsets.all(24.0),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildNotificationItem(
                    context,
                    icon: _iconFor(item['type']?.toString()),
                    iconColor: _colorFor(item['type']?.toString()),
                    title: _titleFor(item),
                    description: item['message']?.toString() ?? '',
                    time: _formatTime(item['timestamp']),
                    onTap: () => _onCustomerNotificationTap(context, item),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String time,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    time,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'booking_confirmed':
        return Icons.check_circle;
      case 'booking_requested':
        return Icons.hourglass_bottom;
      case 'new_booking':
        return Icons.event;
      default:
        return Icons.notifications;
    }
  }

  Color _colorFor(String? type) {
    switch (type) {
      case 'booking_confirmed':
        return const Color(0xFF4CAF50);
      case 'booking_requested':
        return const Color(0xFFFFC107);
      case 'new_booking':
        return const Color(0xFF3F51B5);
      default:
        return const Color(0xFFFF9800);
    }
  }

  String _titleFor(Map<String, dynamic> item) {
    final type = item['type']?.toString() ?? 'Notification';
    switch (type) {
      case 'booking_confirmed':
        return 'Booking Confirmed';
      case 'booking_requested':
        return 'Request Received';
      case 'new_booking':
        return 'New Booking';
      default:
        return 'Notification';
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

  Future<void> _onCustomerNotificationTap(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final bookingId = item['bookingId']?.toString();
    if (bookingId == null || bookingId.isEmpty) return;
    try {
      final snap = await FirebaseDatabase.instance
          .ref('bookings/$bookingId')
          .get();
      if (!snap.exists) return;
      final booking = Map<String, dynamic>.from(snap.value as Map);
      final dateStr = booking['date']?.toString() ?? '';
      final timeStr = booking['time']?.toString() ?? '';
      final dateFmt = DateFormat(
        'EEEE, d MMMM',
      ).format(DateFormat('yyyy-MM-dd').parse(dateStr));
      if (!context.mounted) return;
      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.calendar_today, color: Colors.black54),
                    SizedBox(width: 8),
                    Text(
                      'Appointment Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Hi there! Your appointment is scheduled for $dateFmt at $timeStr.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  (() {
                    final services = booking['services'];
                    if (services is List && services.isNotEmpty) {
                      final titles = services.whereType<String>().toList();
                      return 'Services: ${titles.join(', ')}';
                    }
                    final req = booking['request']?.toString();
                    if (req != null && req.isNotEmpty) {
                      return 'Request: $req';
                    }
                    return 'General Appointment';
                  })(),
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {}
  }
}
