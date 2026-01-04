import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blossom_app/features/staff/services/staff_service.dart';
import 'package:blossom_app/features/staff/screens/notifications/staff_notifications_screen.dart';
import 'package:blossom_app/features/staff/screens/booking/appointment_details_screen.dart';
import 'package:blossom_app/features/staff/screens/booking/search_bookings_screen.dart';

import 'package:blossom_app/features/staff/screens/booking/staff_booking_list_screen.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int? _selectedDay;

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDay = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Beige background
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: StaffService.getAllBookingsStream(),
          builder: (context, snapshot) {
            final allBookings = snapshot.data ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header
                  StreamBuilder<Map<String, dynamic>>(
                    stream: user != null
                        ? StaffService.getStaffProfileStream(user.uid)
                        : Stream.value({}),
                    builder: (context, snapshot) {
                      final data = snapshot.data ?? {};
                      final firstName =
                          data['firstName'] ??
                          user?.displayName?.split(' ').first ??
                          'Staff';

                      return Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(
                              'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=200&auto=format&fit=crop', // Placeholder
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              'Hello, $firstName',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.search,
                              size: 30,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SearchBookingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  // 2. Notifications Button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const StaffNotificationsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.brown.withValues(alpha: 0.1),
                            Colors.brown.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.brown.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.brown,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 3. Appointment Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Appointment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const StaffBookingListScreen(isTab: false),
                            ),
                          );
                        },
                        child: const Text(
                          'View Status >',
                          style: TextStyle(
                            color: Colors.brown,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    height: 130,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEBE0), // Slightly darker beige
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Builder(
                      builder: (context) {
                        // Filter for upcoming (pending/confirmed)
                        final upcoming = allBookings.where((b) {
                          final status = (b['status'] ?? '')
                              .toString()
                              .toLowerCase();
                          return status == 'pending' || status == 'confirmed';
                        }).toList();

                        if (upcoming.isEmpty) {
                          return const Center(
                            child: Text('No upcoming appointments'),
                          );
                        }

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: upcoming.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 15),
                          itemBuilder: (context, index) {
                            final booking = upcoming[index];
                            return _buildAppointmentItem(
                              context,
                              booking['userName'] ?? 'Unknown',
                              'https://images.unsplash.com/photo-1580489944761-15a19d654956?q=80&w=200&auto=format&fit=crop', // Placeholder
                              booking,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 4. Calendar Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Calendar',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 18),
                              onPressed: _prevMonth,
                            ),
                            Text(
                              '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 18),
                              onPressed: _nextMonth,
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.calendar_today, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Weekdays
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            _WeekDayText('mon'),
                            _WeekDayText('tue'),
                            _WeekDayText('wed'),
                            _WeekDayText('thr'),
                            _WeekDayText('fri'),
                            _WeekDayText('sat'),
                            _WeekDayText('sun'),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Dynamic Calendar Grid
                        _CalendarGrid(
                          month: _currentMonth,
                          selectedDay: _selectedDay,
                          bookings: allBookings,
                          onSelectDay: (day) {
                            setState(() {
                              _selectedDay = day;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[m - 1];
  }

  Widget _buildAppointmentItem(
    BuildContext context,
    String name,
    String imageUrl,
    Map<String, dynamic> booking,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailsScreen(booking: booking),
          ),
        );
      },
      child: Column(
        children: [
          CircleAvatar(radius: 30, backgroundImage: NetworkImage(imageUrl)),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _WeekDayText extends StatelessWidget {
  final String text;
  const _WeekDayText(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final int? selectedDay;
  final List<Map<String, dynamic>> bookings;
  final ValueChanged<int> onSelectDay;
  const _CalendarGrid({
    required this.month,
    required this.selectedDay,
    required this.bookings,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(
      month.year,
      month.month,
      1,
    ).weekday; // 1=Mon..7=Sun
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalCells = ((firstWeekday - 1) + daysInMonth);
    final rows = (totalCells / 7.0).ceil();

    // Helper to find bookings for a specific day
    List<Map<String, dynamic>> getBookingsForDay(int day) {
      final dateStr =
          "${month.year}-${month.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
      return bookings.where((b) => b['date'] == dateStr).toList();
    }

    List<Widget> buildRow(int rowIndex) {
      final List<Widget> cells = [];
      for (int col = 0; col < 7; col++) {
        final cellIndex = rowIndex * 7 + col;
        final dayNumber = cellIndex - (firstWeekday - 2);
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          cells.add(const _EmptyDateCell());
        } else {
          final dayBookings = getBookingsForDay(dayNumber);
          cells.add(
            _DateCell(
              day: dayNumber,
              isSelected: selectedDay == dayNumber,
              bookings: dayBookings,
              onTap: () => onSelectDay(dayNumber),
            ),
          );
        }
      }
      return cells;
    }

    final List<Widget> rowsWidgets = [];
    for (int r = 0; r < rows; r++) {
      rowsWidgets.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: buildRow(r),
        ),
      );
      if (r != rows - 1) {
        rowsWidgets.add(const SizedBox(height: 10));
      }
    }

    return Column(children: rowsWidgets);
  }
}

class _EmptyDateCell extends StatelessWidget {
  const _EmptyDateCell();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 35, height: 35);
  }
}

class _DateCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final List<Map<String, dynamic>> bookings;
  final VoidCallback onTap;
  const _DateCell({
    required this.day,
    required this.isSelected,
    required this.bookings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBookings = bookings.isNotEmpty;

    return GestureDetector(
      onTap: () {
        onTap();
        if (hasBookings) {
          _showBookingsDialog(context);
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 35,
            height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFCCBC) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$day',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ),
          if (hasBookings)
            Positioned(
              bottom: 5,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showBookingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Appointments on Day $day'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              String serviceName = 'Service';
              if (booking['services'] is List &&
                  (booking['services'] as List).isNotEmpty) {
                final list = booking['services'] as List;
                serviceName = list.first.toString();
                if (list.length > 1) {
                  serviceName += ' +${list.length - 1} more';
                }
              } else if (booking['request'] is String &&
                  (booking['request'] as String).isNotEmpty) {
                serviceName = booking['request'];
              }

              return ListTile(
                leading: const Icon(Icons.event_note, color: Colors.brown),
                title: Text(booking['userName'] ?? 'Unknown User'),
                subtitle: Text('${booking['time']} - $serviceName'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
