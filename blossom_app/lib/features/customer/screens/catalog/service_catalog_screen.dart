import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:blossom_app/features/customer/screens/booking/booking_screen.dart';
import 'package:blossom_app/features/customer/services/catalog_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceCatalogScreen extends StatefulWidget {
  final String category; // 'Body', 'Facials', 'Beauty'

  const ServiceCatalogScreen({super.key, required this.category});

  @override
  State<ServiceCatalogScreen> createState() => _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends State<ServiceCatalogScreen> {
  @override
  void initState() {
    super.initState();
    // Optimistically try to seed if user is logged in
    _checkAndSeed();
  }

  Future<void> _checkAndSeed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await CatalogService.checkAndSeedData();
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        initialData: CatalogService.getFallbackData(widget.category),
        stream: CatalogService.getServicesStreamWithFallback(widget.category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final services = snapshot.data ?? [];

          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [const Text('No services found in this category.')],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20.0),
            itemCount: services.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final service = services[index];
              return _buildServiceCard(service);
            },
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final imageBase64 = service['imageBase64'] as String?;
    Uint8List? imageBytes;
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(imageBase64);
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEBE6C8), // Lighter olive/beige
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageBytes != null
                ? Image.memory(
                    imageBytes,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    service['image'] ?? service['imageUrl'] ?? '',
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 15),
          // Title
          Text(
            service['title'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange, // Closest match to the orange/gold text
            ),
          ),
          const SizedBox(height: 5),
          // Description
          Text(
            service['description'],
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 10),
          // Time
          Text(
            'Estimate Treatment Time: ${service['time']}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          // Price
          Text(
            'Price: ${service['price']}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 15),
          // Book Now Button
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 120,
              height: 35,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BookingScreen(initialService: service['title']),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Book Now', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
