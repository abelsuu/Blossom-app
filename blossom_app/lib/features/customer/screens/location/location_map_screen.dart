import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationMapScreen extends StatelessWidget {
  const LocationMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map Web View
          SizedBox.expand(child: _buildGoogleMap()),

          // Search Bar (Simulated top)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF102A43),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    "7.7. Location Searched",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8E1), // Beige
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Action for confirm
                        Navigator.pop(context); // Go back for now
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMap() {
    // Papar Century Plaza Coordinates
    // Using an embedded Google Map IFrame for simplicity and "online" feel without API key complexity for now,
    // or a direct static map image if prefered.
    // However, the best "online" experience without an API key is launching the map or using a webview.
    // Since we are in Flutter Web/Mobile, let's use a clickable placeholder that opens the real map,
    // OR a WebView if we had the package.

    // BETTER APPROACH for "Online":
    // Display a high-quality interactive-looking placeholder that actually launches the real Google Maps app/site.
    return InkWell(
      onTap: _launchMaps,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Base Map Layer (Network Image for "Online" look)
          Image.network(
            'https://mt1.google.com/vt/lyrs=m&x=0&y=0&z=1', // Generic tile or specific static map if available
            // Since we can't easily get a static map without an API key, we will use a styled container
            // that LOOKS like a map loading or a specific placeholder image if we had one.
            // Let's use a Container with a subtle pattern or a specific color that matches Google Maps water/land.
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(
              color: const Color(0xFFe5e3df),
            ), // Google Maps default gray
          ),
          Container(color: const Color(0xFFe5e3df)), // Background
          // 2. The "Click to Open Google Maps" Message
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_outlined, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Open in Google Maps",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.open_in_new, size: 16, color: Colors.blue),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchMaps() async {
    // Century Plaza Papar coordinates
    const double lat = 5.7345;
    const double lng = 115.9319;
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=Century+Plaza+Papar+Sabah',
    );

    if (!await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $googleMapsUrl');
    }
  }
}
