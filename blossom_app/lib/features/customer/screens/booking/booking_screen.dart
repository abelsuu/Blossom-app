import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:blossom_app/features/customer/screens/booking/booking_success_screen.dart';
import 'package:blossom_app/features/customer/screens/booking/booking_unavailable_screen.dart';
import 'package:blossom_app/features/customer/services/catalog_service.dart';
import 'package:blossom_app/common/widgets/multi_select_dropdown.dart';

class BookingScreen extends StatefulWidget {
  final String? initialService;
  final bool isTab;

  const BookingScreen({super.key, this.initialService, this.isTab = false});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedDateIndex = 0;
  String? _selectedTimeSlot;
  final TextEditingController _requestController = TextEditingController();
  late List<DateTime> _dates;
  List<String> _selectedServices = [];
  // bool _dbConnected = false;
  late DateTime _monthCursor; // first day of current month
  late DateTime _minMonth; // earliest month allowed
  late DateTime _maxMonth; // latest month allowed

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthCursor = DateTime(now.year, now.month, 1);
    _minMonth = _monthCursor;
    _maxMonth = DateTime(now.year, now.month + 5, 1); // allow 6 months range
    _dates = _generateDatesForMonth(_monthCursor);

    if (widget.initialService != null) {
      _selectedServices.add(widget.initialService!);
    }
    // Ensure service catalog exists for dropdown
    CatalogService.checkAndSeedData();
    // Monitor connection status
    try {
      // Force connection attempt
      FirebaseDatabase.instance.goOnline();
    } catch (e) {
      debugPrint('Error going online: $e');
    }
  }

  List<DateTime> _generateDatesForMonth(DateTime monthStart) {
    final now = DateTime.now();
    final isCurrentMonth =
        monthStart.year == now.year && monthStart.month == now.month;
    final startDay = isCurrentMonth ? now.day : 1;

    final nextMonth = DateTime(monthStart.year, monthStart.month + 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1)).day;

    // If we are past the last day (e.g. today is 31st), handle gracefully
    if (startDay > lastDay) return [];

    final count = lastDay - startDay + 1;

    return List.generate(
      count,
      (i) => DateTime(monthStart.year, monthStart.month, startDay + i),
    );
  }

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  final List<String> _morningSlots = ['9:00', '10:00', '11:00'];
  final List<String> _afternoonSlots = [
    '1:00',
    '2:00',
    '3:00',
    '4:00',
    '5:00',
    '6:00',
  ];

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildTimeGrid(List<String> slots) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final selectedDate = _dates[_selectedDateIndex];
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        bool isEnabled = true;

        if (isToday) {
          final timeParts = slot.split(':');
          var hour = int.parse(timeParts[0]);
          // Adjust for PM slots (1-6 are PM, 9-11 are AM)
          if (hour < 7) hour += 12;

          final slotTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            hour,
          );
          if (slotTime.isBefore(now)) {
            isEnabled = false;
          }
        }

        final isSelected = _selectedTimeSlot == slot;
        return GestureDetector(
          onTap: isEnabled
              ? () {
                  setState(() {
                    _selectedTimeSlot = slot;
                  });
                }
              : null,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isEnabled ? Colors.white : Colors.grey[200]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
            ),
            child: Text(
              slot,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isEnabled ? Colors.black87 : Colors.grey[500]),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        title: Text(
          'Book Appointment',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3142),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header with navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _monthCursor.isAfter(_minMonth)
                      ? () {
                          setState(() {
                            _monthCursor = DateTime(
                              _monthCursor.year,
                              _monthCursor.month - 1,
                              1,
                            );
                            _dates = _generateDatesForMonth(_monthCursor);
                            _selectedDateIndex = 0;
                            _selectedTimeSlot = null;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_monthCursor),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                IconButton(
                  onPressed: _monthCursor.isBefore(_maxMonth)
                      ? () {
                          setState(() {
                            _monthCursor = DateTime(
                              _monthCursor.year,
                              _monthCursor.month + 1,
                              1,
                            );
                            _dates = _generateDatesForMonth(_monthCursor);
                            _selectedDateIndex = 0;
                            _selectedTimeSlot = null;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Date Selector
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final date = _dates[index];
                  final isSelected = index == _selectedDateIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDateIndex = index;
                        // Reset time slot if date changes
                        _selectedTimeSlot = null;
                      });
                    },
                    child: Container(
                      width: 65,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFD4A373)
                            : Colors.white, // Earthy/Dusty tone
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(0xFFD4A373).withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: isSelected
                            ? null
                            : Border.all(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE').format(date).toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('d').format(date),
                            style: TextStyle(
                              fontSize: 20,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF2D3142),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Morning Slots
            _buildSectionTitle('Morning'),
            const SizedBox(height: 16),
            _buildTimeGrid(_morningSlots),
            const SizedBox(height: 32),

            // Afternoon Slots
            _buildSectionTitle('Afternoon'),
            const SizedBox(height: 16),
            _buildTimeGrid(_afternoonSlots),
            const SizedBox(height: 32),

            // Choose Services (max 3, one per category)
            Text(
              'Choose Services (max 3, one per category)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 10),

            StreamBuilder<List<Map<String, dynamic>>>(
              initialData: CatalogService.getFallbackAllServices(),
              stream: CatalogService.getAllServicesStreamWithFallback(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                final services = snapshot.data ?? [];
                final titles = services
                    .map((s) => s['title'])
                    .whereType<String>()
                    .where((t) => t.trim().isNotEmpty)
                    .toSet()
                    .toList();

                if (titles.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline, color: Colors.grey),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No services available. Tap refresh to load catalog.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await CatalogService.checkAndSeedData();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Refreshing services...'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Services'),
                        ),
                      ),
                    ],
                  );
                }

                return MultiSelectDropdownWithChips(
                  allItems: titles,
                  selectedItems: _selectedServices,
                  onChanged: (list) {
                    setState(() {
                      _selectedServices = list;
                    });
                  },
                  hint: 'Select services',
                  maxSelection: 3,
                );
              },
            ),
            const SizedBox(height: 30),

            // Requests
            Text(
              'Requests',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _requestController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add any special requests here...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Book Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedTimeSlot != null
                    ? () async {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        if (_selectedTimeSlot == '6:00') {
                          Navigator.pop(context); // Dismiss loading
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const BookingUnavailableScreen(),
                            ),
                          );
                        } else {
                          // Real booking logic
                          try {
                            final User? user =
                                FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              Navigator.pop(context); // Dismiss loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please login to book'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            final DateTime selectedDate =
                                _dates[_selectedDateIndex];
                            final String formattedDate = DateFormat(
                              'yyyy-MM-dd',
                            ).format(selectedDate);
                            final String displayDate = DateFormat(
                              'EEEE, d MMMM',
                            ).format(selectedDate);

                            // 1. Transaction to Prevent Double Booking
                            final String safeTime = _selectedTimeSlot!
                                .replaceAll('.', ':');
                            final availabilityRef = FirebaseDatabase.instance
                                .ref('availability/$formattedDate/$safeTime');

                            final DatabaseReference ref = FirebaseDatabase
                                .instance
                                .ref("bookings")
                                .push();
                            final String bookingId = ref.key!;

                            try {
                              final transactionResult = await availabilityRef
                                  .runTransaction((Object? currentData) {
                                    if (currentData == null) {
                                      return Transaction.success(bookingId);
                                    }
                                    return Transaction.abort();
                                  });

                              if (!transactionResult.committed) {
                                if (context.mounted) {
                                  Navigator.pop(context); // Dismiss loading
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'This time slot is already booked. Please select another.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }
                            } catch (e) {
                              debugPrint('Transaction failed: $e');
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Booking failed: $e')),
                                );
                              }
                              return;
                            }

                            debugPrint(
                              'Booking: slot reserved, writing data key=$bookingId uid=${user.uid}',
                            );

                            final bookingData = {
                              "userId": user.uid,
                              "userName": user.displayName ?? "Guest",
                              "date": formattedDate,
                              "time": _selectedTimeSlot,
                              "request": _requestController.text,
                              if (_selectedServices.isNotEmpty)
                                "services": _selectedServices,
                              "status": "pending",
                              "timestamp": ServerValue.timestamp,
                            };

                            // Perform write with mandatory await and timeout
                            // This ensures we verify connection by actually trying to write
                            try {
                              await ref
                                  .set(bookingData)
                                  .timeout(
                                    const Duration(seconds: 5),
                                    onTimeout: () {
                                      throw Exception('Connection timeout');
                                    },
                                  );
                            } catch (e) {
                              // Rollback availability if write fails
                              await availabilityRef.remove();
                              rethrow;
                            }

                            debugPrint('Booking: write success key=${ref.key}');

                            // Notifications
                            try {
                              await FirebaseDatabase.instance
                                  .ref('notifications/staff')
                                  .push()
                                  .set({
                                    'type': 'new_booking',
                                    'message':
                                        'You have a new appointment request from ${user.displayName ?? 'a customer'} on $displayDate at ${_selectedTimeSlot!}. Tap to review and confirm.',
                                    'date': formattedDate,
                                    'time': _selectedTimeSlot,
                                    'bookingId': ref.key,
                                    'timestamp': ServerValue.timestamp,
                                  });
                              await FirebaseDatabase.instance
                                  .ref('notifications/${user.uid}')
                                  .push()
                                  .set({
                                    'type': 'booking_requested',
                                    'message':
                                        'Thanks for your request! We\'ll confirm soon. Your appointment is requested for $displayDate at ${_selectedTimeSlot!}. Tap to view the summary.',
                                    'date': formattedDate,
                                    'time': _selectedTimeSlot,
                                    'bookingId': ref.key,
                                    'timestamp': ServerValue.timestamp,
                                  });
                            } catch (_) {}

                            if (!context.mounted) return;
                            Navigator.pop(context); // Dismiss loading

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingSuccessScreen(
                                  date: displayDate,
                                  time: _selectedTimeSlot!,
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            Navigator.pop(context); // Dismiss loading

                            // Show strict offline message
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Internet Required'),
                                content: Text(
                                  'You need an internet connection to book an appointment. Please check your connection and try again.\n\nError: $e',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      }
                    : null, // Disable if no time selected
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  shadowColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.4),
                ),
                child: const Text(
                  'Book Appointment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
