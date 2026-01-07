import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'map_embed_stub.dart' if (dart.library.html) 'map_embed_web.dart';

class LocationMapScreen extends StatelessWidget {
  const LocationMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _buildMap()),

          // Bottom Sheet
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8E1), // Beige
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.my_location, color: Colors.black87),
                    SizedBox(width: 12),
                    Text(
                      'Century Plaza',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 36.0),
                  child: Text(
                    'Lot 18 C 1st Floor Papar Century Plaza Papar Sabah',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    const double lat = 5.7358; // Stella Beauty Salon / Century Plaza Block C
    const double lng = 115.9321;
    return Stack(
      fit: StackFit.expand,
      children: [
        buildMapEmbed(lat, lng),
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _launchMaps,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in Google Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchMaps() async {
    // Stella Beauty Salon / Century Plaza Block C
    // const double lat = 5.7358;
    // const double lng = 115.9321;
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=Stella+Beauty+Salon+Spa+Papar+Sabah',
    );

    if (!await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $googleMapsUrl');
    }
  }
}
