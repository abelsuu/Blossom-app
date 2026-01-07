import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCancelDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: Colors.white,
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Cancel Appointment?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to cancel this appointment? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Keep it',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            // Update booking status
                            await FirebaseDatabase.instance
                                .ref('bookings/$bookingId')
                                .update({
                                  'status': 'cancelled',
                                  'cancelledBy': 'customer',
                                  'cancellationReason': 'Cancelled by customer',
                                });

                            // Send Notification to Staff
                            try {
                              final bookingSnapshot = await FirebaseDatabase
                                  .instance
                                  .ref('bookings/$bookingId')
                                  .get();

                              if (bookingSnapshot.exists) {
                                final booking = Map<String, dynamic>.from(
                                  bookingSnapshot.value as Map,
                                );
                                final date = booking['date'] ?? 'Unknown Date';
                                final time = booking['time'] ?? 'Unknown Time';
                                final customerName =
                                    booking['userName'] ?? 'Customer';

                                // Push to a shared staff notifications node
                                await FirebaseDatabase.instance
                                    .ref('notifications/staff')
                                    .push()
                                    .set({
                                      'title': 'Booking Cancelled',
                                      'message':
                                          '$customerName cancelled appointment on $date at $time',
                                      'timestamp': ServerValue.timestamp,
                                      'type': 'booking_cancelled',
                                      'bookingId': bookingId,
                                      'read': false,
                                    });
                              }
                            } catch (e) {
                              debugPrint(
                                'Error sending staff notification: $e',
                              );
                            }

                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Yes, Cancel',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _getBookingsStream(bool isUpcoming) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    // Use client-side filtering for robustness against missing indexes
    final query = FirebaseDatabase.instance.ref('bookings');
    // Force sync to ensure we get the latest data
    if (!kIsWeb) {
      query.keepSynced(true);
    }

    return query.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<dynamic, dynamic> bookingsMap = data as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> bookings = [];

      bookingsMap.forEach((key, value) {
        final booking = Map<String, dynamic>.from(value as Map);
        // Client-side filter: Only show bookings for this user
        if (booking['userId'] == user.uid) {
          booking['id'] = key;
          bookings.add(booking);
        }
      });

      // Filter and sort
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final filtered = bookings.where((booking) {
        try {
          final bookingDate = DateFormat('yyyy-MM-dd').parse(booking['date']);
          final status = (booking['status'] ?? '').toString().toLowerCase();
          final isCompletedOrCancelled =
              status == 'completed' || status == 'cancelled';

          if (isUpcoming) {
            // Show only if NOT completed/cancelled AND date is today/future
            return !isCompletedOrCancelled &&
                (bookingDate.isAfter(today) ||
                    bookingDate.isAtSameMomentAs(today));
          } else {
            // Show if completed/cancelled OR date is past
            return isCompletedOrCancelled || bookingDate.isBefore(today);
          }
        } catch (e) {
          return false;
        }
      }).toList();

      // Sort by date
      filtered.sort((a, b) {
        final dateA = DateFormat('yyyy-MM-dd').parse(a['date']);
        final dateB = DateFormat('yyyy-MM-dd').parse(b['date']);
        return isUpcoming ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      });

      return filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
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
            icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Your Bookings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3142),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicator: BoxDecoration(
                color: const Color(0xFFD4A373), // Earthy tone
                borderRadius: BorderRadius.circular(21),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4A373).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Upcoming Tab
                _BookingsList(
                  isUpcoming: true,
                  bookingsStream: _getBookingsStream(true),
                  onCancel: _showCancelDialog,
                ),
                // Past Tab
                _BookingsList(
                  isUpcoming: false,
                  bookingsStream: _getBookingsStream(false),
                  onCancel: _showCancelDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingsList extends StatefulWidget {
  final bool isUpcoming;
  final Stream<List<Map<String, dynamic>>> bookingsStream;
  final Function(String) onCancel;

  const _BookingsList({
    required this.isUpcoming,
    required this.bookingsStream,
    required this.onCancel,
  });

  @override
  State<_BookingsList> createState() => _BookingsListState();
}

class _BookingsListState extends State<_BookingsList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.bookingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return Center(
            child: Text(
              widget.isUpcoming
                  ? 'No upcoming\nappointment'
                  : 'No past\nbookings',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black45,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _buildBookingCard(context, booking);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> booking) {
    // Format date for display
    String displayDate = booking['date'];
    try {
      final date = DateFormat('yyyy-MM-dd').parse(booking['date']);
      displayDate = DateFormat('d MMM yyyy').format(date);
    } catch (e) {
      // Keep original string if parse fails
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A373).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.spa_rounded,
                      color: Color(0xFFD4A373),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Blossom Spa',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
              if (widget.isUpcoming)
                InkWell(
                  onTap: () => widget.onCancel(booking['id']),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Text(
            (() {
              final services = booking['services'];
              if (services is List && services.isNotEmpty) {
                final titles = services.whereType<String>().toList();
                return titles.join(', ');
              }
              final req = booking['request'];
              if (req is String && req.isNotEmpty) return req;
              return 'General Appointment';
            })(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 8),
              Text(
                displayDate,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 20),
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 8),
              Text(
                booking['time'],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: (() {
                final s = (booking['status']?.toString() ?? 'pending')
                    .toLowerCase();
                if (s == 'confirmed') return const Color(0xFFE8F5E9);
                if (s == 'in progress') return const Color(0xFFE3F2FD);
                if (s == 'completed') return Colors.grey.withValues(alpha: 0.1);
                if (s == 'cancelled') return const Color(0xFFFDECEA);
                return const Color(0xFFFFF3CD);
              })(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  (() {
                    final s = (booking['status']?.toString() ?? 'pending')
                        .toLowerCase();
                    if (s == 'confirmed') {
                      return Icons.check_circle_outline_rounded;
                    }
                    if (s == 'in progress') return Icons.autorenew_rounded;
                    if (s == 'completed') return Icons.history_rounded;
                    if (s == 'cancelled') return Icons.cancel_outlined;
                    return Icons.hourglass_bottom_rounded;
                  })(),
                  size: 16,
                  color: (() {
                    final s = (booking['status']?.toString() ?? 'pending')
                        .toLowerCase();
                    if (s == 'confirmed') return Colors.green[700];
                    if (s == 'in progress') return Colors.blue[700];
                    if (s == 'completed') return Colors.grey[600];
                    if (s == 'cancelled') return Colors.red[700];
                    return const Color(0xFF8A6D3B);
                  })(),
                ),
                const SizedBox(width: 8),
                Text(
                  (() {
                    switch ((booking['status']?.toString() ?? 'pending')
                        .toLowerCase()) {
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
                  })(),
                  style: TextStyle(
                    color: (() {
                      final s = (booking['status']?.toString() ?? 'pending')
                          .toLowerCase();
                      if (s == 'confirmed') return Colors.green[700];
                      if (s == 'in progress') return Colors.blue[700];
                      if (s == 'completed') return Colors.grey[600];
                      if (s == 'cancelled') return Colors.red[700];
                      return const Color(0xFF8A6D3B);
                    })(),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
