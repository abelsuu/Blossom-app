import 'package:flutter/material.dart';
import 'package:blossom_app/features/staff/services/staff_service.dart';
import 'package:blossom_app/features/staff/screens/booking/appointment_details_screen.dart';
import 'package:blossom_app/features/staff/screens/booking/calendar_selection_screen.dart';
import 'package:blossom_app/features/staff/screens/booking/status_categories_screen.dart';
import 'package:blossom_app/features/staff/screens/booking/service_gallery_screen.dart';

class SearchBookingsScreen extends StatefulWidget {
  final bool isTab;

  const SearchBookingsScreen({super.key, this.isTab = false});

  @override
  State<SearchBookingsScreen> createState() => _SearchBookingsScreenState();
}

class _SearchBookingsScreenState extends State<SearchBookingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

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
                    'Search Bookings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
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
              const SizedBox(height: 10),
              const Divider(color: Colors.black54, thickness: 1),
              const SizedBox(height: 20),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by name...',
                    suffixIcon: Icon(
                      Icons.search,
                      size: 28,
                      color: Colors.black,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Content: Buttons OR Search Results
              Expanded(
                child: _searchQuery.isEmpty
                    ? _buildCategories(context)
                    : _buildSearchResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return Column(
      children: [
        _buildCategoryButton(
          context,
          'Date Range',
          const CalendarSelectionScreen(),
        ),
        const SizedBox(height: 15),
        _buildCategoryButton(
          context,
          'Status',
          const StatusCategoriesScreen(),
        ),
        const SizedBox(height: 15),
        _buildCategoryButton(
          context,
          'Service Types',
          const ServiceGalleryScreen(),
        ),
      ],
    );
  }

  Widget _buildCategoryButton(
    BuildContext context,
    String title,
    Widget destination,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC5C0A0).withValues(alpha: 0.3), // Light Olive/Beige gradient look
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.centerLeft,
          elevation: 0,
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: StaffService.getAllBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allBookings = snapshot.data ?? [];
          final filteredBookings = allBookings.where((booking) {
            final name = (booking['userName'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery.toLowerCase());
          }).toList();

          if (filteredBookings.isEmpty) {
            return const Center(child: Text('No bookings found'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: filteredBookings.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: Colors.grey,
            ),
            itemBuilder: (context, index) {
              final booking = filteredBookings[index];
              final name = booking['userName'] ?? 'Unknown';
              final request = booking['request'] ?? 'Service';

              return ListTile(
                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '$request - ${booking['status'] ?? 'pending'}',
                  style: const TextStyle(fontSize: 12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                dense: true,
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
              );
            },
          );
        },
      ),
    );
  }
}
