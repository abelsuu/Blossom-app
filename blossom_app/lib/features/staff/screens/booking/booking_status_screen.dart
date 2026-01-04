import 'package:flutter/material.dart';
import 'package:blossom_app/features/staff/services/staff_service.dart';
import 'package:blossom_app/features/staff/screens/booking/appointment_details_screen.dart';

class BookingStatusScreen extends StatefulWidget {
  final String initialStatus;
  final bool isTab;

  const BookingStatusScreen({
    super.key,
    this.initialStatus = 'Pending',
    this.isTab = false,
  });

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> {
  late String _currentStatus;
  final String _selectedMonth = 'December';
  final String _selectedYear = '2025';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Beige background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.reply,
                  color: Colors.black,
                  size: 30,
                ), // Curved arrow style
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: StaffService.getAllBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allBookings = snapshot.data ?? [];
          final currentList = allBookings.where((b) {
            final status = (b['status'] ?? 'pending').toString().toLowerCase();
            return status == _currentStatus.toLowerCase();
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.black54, thickness: 1),
                const SizedBox(height: 20),

                // Status Selector Button
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D4037), // Dark Brown
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    constraints: const BoxConstraints(minWidth: 300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    onSelected: (String value) {
                      setState(() {
                        _currentStatus = value;
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        'Pending',
                        'Confirmed',
                        'In Progress',
                        'Completed',
                        'Cancelled',
                      ].map((String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Text(choice),
                        );
                      }).toList();
                    },
                    child: Center(
                      child: Text(
                        _currentStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Date Filters
                _buildDateFilterRow('Month:', _selectedMonth),
                const SizedBox(height: 10),
                _buildDateFilterRow('Year:', _selectedYear),
                const SizedBox(height: 30),

                // Status Title and Count
                Text(
                  '$_currentStatus Bookings',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text.rich(
                  TextSpan(
                    text: '${currentList.length} $_currentStatus Bookings',
                    style: const TextStyle(
                      color: Colors.orange, // Use orange for count text
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    children: const [
                      TextSpan(
                        text: ' for this month',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Booking List
                if (currentList.isEmpty)
                  const Center(
                    child: Text("No bookings found for this status."),
                  ),
                ...currentList.map((booking) => _buildBookingCard(booking)),

                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateFilterRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0), // Light peach/beige for input
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final name = booking['userName'] ?? 'Unknown';
    // Use a placeholder if image is not available in booking data
    // Ideally user profile image should be fetched, but for now placeholder
    final image =
        'https://images.unsplash.com/photo-1580489944761-15a19d654956?q=80&w=200&auto=format&fit=crop';
    final request = booking['request'] ?? 'Service';
    final date = booking['date'] ?? '';
    final time = booking['time'] ?? '';
    final bookingId = booking['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(image),
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          subtitle: Text(
            '$request • $date $time',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentStatus == 'Pending') ...[
                    _buildActionItem('Confirm', bookingId, 'confirmed'),
                    const SizedBox(height: 10),
                    _buildActionItem('Cancel', bookingId, 'cancelled'),
                  ] else if (_currentStatus == 'Confirmed') ...[
                    _buildActionItem('Complete', bookingId, 'completed'),
                    const SizedBox(height: 10),
                    _buildActionItem('Cancel', bookingId, 'cancelled'),
                  ] else ...[
                    _buildViewDetailsItem(booking),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(String label, String bookingId, String newStatus) {
    return GestureDetector(
      onTap: () async {
        await StaffService.updateBookingStatus(bookingId, newStatus);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Booking $newStatus')));
        }
      },
      child: Row(
        children: [
          Icon(
            newStatus == 'cancelled' ? Icons.close : Icons.check,
            size: 16,
            color: newStatus == 'cancelled' ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildViewDetailsItem(Map<String, dynamic> booking) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailsScreen(
              booking: booking,
            ),
          ),
        );
      },
      child: const Text(
        'View Details',
        style: TextStyle(fontSize: 14, color: Colors.blue),
      ),
    );
  }
}
