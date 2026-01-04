import 'package:flutter/material.dart';
import 'package:blossom_app/features/staff/services/staff_service.dart';
import 'package:blossom_app/features/staff/screens/booking/appointment_details_screen.dart';

class StatusCategoriesScreen extends StatelessWidget {
  const StatusCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Beige
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.reply, size: 30, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Status',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildStatusPill(context, 'Pending'),
            const SizedBox(height: 15),
            _buildStatusPill(context, 'Confirmed'),
            const SizedBox(height: 15),
            _buildStatusPill(context, 'In Progress'),
            const SizedBox(height: 15),
            _buildStatusPill(context, 'Completed'),
            const SizedBox(height: 15),
            _buildStatusPill(context, 'Cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(BuildContext context, String status) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FilteredResultsScreen(status: status),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFAEBD7), // Light Peach
          foregroundColor: const Color(0xFF8B4513), // Brown text
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Text(
          status,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class FilteredResultsScreen extends StatefulWidget {
  final String status;

  const FilteredResultsScreen({super.key, required this.status});

  @override
  State<FilteredResultsScreen> createState() => _FilteredResultsScreenState();
}

class _FilteredResultsScreenState extends State<FilteredResultsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.reply, size: 30, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.status,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: StaffService.getAllBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allBookings = snapshot.data ?? [];
          final targetStatus = widget.status.toLowerCase();
          
          final filteredBookings = allBookings.where((b) {
             final s = (b['status'] ?? '').toString().toLowerCase();
             if (targetStatus == 'in progress') return s == 'in progress' || s == 'inprogress';
             return s == targetStatus;
          }).toList();

          if (filteredBookings.isEmpty) {
            return const Center(child: Text('No bookings found for this status'));
          }

          return Column(
            children: [
               Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D4037), // Dark Brown
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${filteredBookings.length} ${widget.status} Status',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return _buildBookingAccordion(booking);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingAccordion(Map<String, dynamic> booking) {
    final name = booking['userName'] ?? 'Unknown';
    final imageUrl = 'https://images.unsplash.com/photo-1580489944761-15a19d654956?q=80&w=200&auto=format&fit=crop';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(imageUrl),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
           Padding(
             padding: const EdgeInsets.all(15.0),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 ElevatedButton(
                   onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppointmentDetailsScreen(booking: booking),
                        ),
                      );
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFFD4AF37),
                     foregroundColor: Colors.white,
                   ),
                   child: const Text('View Details'),
                 ),
               ],
             ),
           )
        ],
      ),
    );
  }
}
