/*
  Customer home screen for Blossom app. Displays greeting,
  loyalty card, upcoming appointment, location, promotions and
  service catalog. Navigation tabs switch between Home, Booking,
  Facial AI, Chat and Profile.
*/

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:blossom_app/features/customer/screens/booking/booking_screen.dart';
import 'package:blossom_app/features/customer/screens/ai_skin_analysis/ai_skin_analysis_screen.dart'
    show AiSkinAnalysisScreen;
import 'package:blossom_app/features/customer/screens/catalog/service_catalog_screen.dart';
import 'package:blossom_app/features/customer/screens/rewards/points_rewards_screen.dart';
import 'package:blossom_app/features/customer/screens/notifications/notification_screen.dart';
import 'package:blossom_app/features/customer/screens/profile/profile_screen.dart';
import 'package:blossom_app/features/customer/screens/booking/my_bookings_screen.dart';
import 'package:blossom_app/features/customer/screens/chat/chat_connect_screen.dart';
import 'package:blossom_app/features/customer/screens/location/contact_info_screen.dart';
import 'package:blossom_app/features/customer/services/catalog_service.dart';
import 'package:blossom_app/features/customer/services/promotions_service.dart';
import 'package:blossom_app/features/customer/services/user_service.dart';
import 'package:blossom_app/features/customer/screens/special_offer_details_screen.dart';
import 'package:intl/intl.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        debugPrint('User authenticated: ${user.uid}. Checking catalog data...');
        CatalogService.checkAndSeedData();
        UserService.checkAndSeedUserData();
        PromotionsService.checkAndSeedPromotions();
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Beige background
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeContent(),
            const BookingScreen(isTab: true),
            const AiSkinAnalysisScreen(showBackButton: false),
            const ChatConnectScreen(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: const Color(0xFFFFF8E1),
        indicatorColor: const Color(0xFFCFA6A6).withValues(alpha: 0.5),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Booking',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'FacialAI',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          _buildHeader(),
          const SizedBox(height: 30),

          // 2. Loyalty Card
          _buildLoyaltyCard(),
          const SizedBox(height: 25),

          // 3. Upcoming Appointment
          _buildAppointmentCard(),
          const SizedBox(height: 25),

          // 3.5 Location Card (Century Plaza)
          _buildLocationCard(),
          const SizedBox(height: 25),

          // 4. Promo Banner
          const Text(
            'Special Offers',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildPromoBanner(),
          const SizedBox(height: 30),
          const Text(
            'Recommended for You',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildRecommendations(),
          const SizedBox(height: 30),

          // 5. Catalog
          const Text(
            'Our Services',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildCatalogGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final User? user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? 'Guest';
    final String firstName = displayName.split(' ').first;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $firstName',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4E342E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ready to glow today?',
              style: TextStyle(fontSize: 16, color: Colors.brown[400]),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_outlined,
              size: 28,
              color: Color(0xFF4E342E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoyaltyCard() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<Map<String, dynamic>>(
      stream: UserService.getLoyaltyStream(user.uid),
      builder: (context, snapshot) {
        final data =
            snapshot.data ?? {'points': 0, 'vouchers': 0, 'tier': 'Bronze'};
        final points = data['points'] ?? 0;
        final vouchers = data['vouchers'] ?? 0;
        final tier = (() {
          if (data['tier'] is String && (data['tier'] as String).isNotEmpty) {
            return data['tier'];
          }
          if (points >= 150) return 'Gold';
          if (points >= 50) return 'Silver';
          return 'Bronze';
        })();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PointsRewardsScreen(),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFCFA6A6), Color(0xFFBCAAA4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFCFA6A6).withValues(alpha: 0.4),
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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blossom Rewards',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        // Dynamic tier label
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLoyaltyStat(points.toString(), 'Points'),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    _buildLoyaltyStat(vouchers.toString(), 'Vouchers'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$tier Member',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoyaltyStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ContactInfoScreen()),
        );
      },
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.brown.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5FE), // Light blue for location
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.store_mall_directory_rounded,
                  color: Color(0xFF0288D1), // Blue
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Century Plaza',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View location & hours',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<Map<String, dynamic>?>(
      stream: UserService.getNextAppointmentStream(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.brown.withValues(alpha: 0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFFCFA6A6),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No Upcoming Booking',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Book your next session',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _onItemTapped(1),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Book'),
                  ),
                ],
              ),
            ),
          );
        }

        final booking = snapshot.data!;
        final dateStr = booking['date'] ?? 'Unknown Date';
        final timeStr = booking['time'] ?? 'Unknown Time';

        String dayOfWeek = '';
        String dayNumber = '';
        String month = '';

        try {
          final date = DateTime.parse(dateStr);
          dayOfWeek = DateFormat('EEEE').format(date);
          dayNumber = DateFormat('d').format(date);
          month = DateFormat('MMM').format(date);
        } catch (e) {
          dayOfWeek = dateStr;
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFCFA6A6).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            dayNumber,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4E342E),
                            ),
                          ),
                          Text(
                            month,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFCFA6A6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dayOfWeek,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF4E342E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Century Plaza',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyBookingsScreen(),
                          ),
                        );
                      },
                      child: const Text('View Details'),
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

  Widget _buildPromoBanner() {
    return SizedBox(
      height: 180,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        initialData: PromotionsService.getFallbackPromotions(),
        stream: PromotionsService.getPromotionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final promotions = snapshot.data ?? [];
          if (promotions.isEmpty) {
            return const Center(child: Text('No active promotions'));
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: promotions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final promo = promotions[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SpecialOfferDetailsScreen(promo: promo),
                    ),
                  );
                },
                child: _buildDealCard(
                  color: Color(promo['color'] ?? 0xFF556B2F),
                  title: promo['title'] ?? '',
                  subtitle: promo['subtitle'] ?? '',
                  imageUrl: promo['imageUrl'] ?? '',
                  imageBase64: promo['imageBase64'],
                  textColor: Color(promo['textColor'] ?? 0xFFFFFFFF),
                  pillColor: Color(promo['pillColor'] ?? 0xCCFFFFFF),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDealCard({
    required Color color,
    required String title,
    required String subtitle,
    required String imageUrl,
    String? imageBase64,
    required Color textColor,
    required Color pillColor,
  }) {
    ImageProvider? imageProvider;
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(imageBase64));
      } catch (_) {}
    }
    if (imageProvider == null && imageUrl.isNotEmpty) {
      imageProvider = NetworkImage(imageUrl);
    }

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -10,
            bottom: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: imageProvider != null
                    ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                    : null,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.85, // Taller cards
      children: [
        _buildCatalogItem(
          'Body',
          'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?q=80&w=400',
        ),
        _buildCatalogItem(
          'Facials',
          'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?q=80&w=400',
        ),
        _buildCatalogItem(
          'Beauty',
          'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?q=80&w=400',
        ),
        _buildCatalogItem(
          'Product\n(Soon)',
          'https://images.unsplash.com/photo-1596462502278-27bfdd403348?q=80&w=400',
          isOverlay: true,
        ),
      ],
    );
  }

  Widget _buildCatalogItem(
    String title,
    String imageUrl, {
    bool isOverlay = false,
  }) {
    return GestureDetector(
      onTap: () {
        String category = title.replaceAll('\n(Soon)', '');
        if (category == 'Product') return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceCatalogScreen(category: category),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
            ),
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    return SizedBox(
      height: 120,
      child: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('bookings').onValue,
        builder: (context, snapshot) {
          final data = snapshot.data?.snapshot.value;
          if (data == null) return const SizedBox.shrink();
          final Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;
          final Map<String, int> counts = {};
          map.forEach((key, value) {
            final b = Map<String, dynamic>.from(value as Map);
            if (b['userId'] == user.uid) {
              if (b['services'] is List) {
                for (final s in (b['services'] as List)) {
                  if (s is String && s.isNotEmpty) {
                    counts[s] = (counts[s] ?? 0) + 1;
                  }
                }
              } else if (b['request'] is String) {
                final s = b['request'] as String;
                if (s.isNotEmpty) counts[s] = (counts[s] ?? 0) + 1;
              }
            }
          });
          final items = counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final top = items.take(6).map((e) => e.key).toList();
          if (top.isEmpty) {
            return const Text('No recommendations yet');
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: top.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final name = top[index];
              final cat = (() {
                final n = name.toLowerCase();
                if (n.contains('facial')) {
                  return 'Facials';
                }
                if (n.contains('manicure') ||
                    n.contains('pedicure') ||
                    n.contains('polish') ||
                    n.contains('nail')) {
                  return 'Beauty';
                }
                return 'Body';
              })();
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceCatalogScreen(category: cat),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.brown.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Based on your bookings',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4E342E),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                          const SizedBox(width: 4),
                          const Text('View', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
