import 'package:flutter/material.dart';
import 'package:blossom_app/features/customer/screens/contact/location_map_screen.dart';

class ContactInfoScreen extends StatelessWidget {
  const ContactInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Beige background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // If this is part of the main tabs, maybe we don't pop? 
            // But if we navigated here, we pop.
            // Let's assume standard pop behavior.
            // However, if integrated into BottomNav, this button might need to do nothing or switch tab.
            // For now, let's keep it but check navigation context if needed.
            // Since we are replacing "Chat" tab, this might be the root of that tab.
            // If so, back button might not be needed or could go to Home.
            // But let's leave it functional for now.
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Contact Info',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            
            // Info List
            _buildContactItem(Icons.location_on_outlined, 'Century Plaza'),
            _buildContactItem(Icons.phone_outlined, '+60 11-6083 1043'),
            _buildContactItem(Icons.facebook, 'Annis BeautyCare', color: Colors.blue),
            _buildContactItem(Icons.camera_alt_outlined, 'blossombeautywellness', color: Colors.pink), // Instagram placeholder
            
            const SizedBox(height: 40),
            
            // Hours
            const Text(
              'Hours',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildHourRow('Mon', 'Closed'),
            _buildHourRow('Tue - Sat', '9:00 am - 5:30 pm'),
            _buildHourRow('Sat', '9:00 am - 4:30 pm'),
            
            const SizedBox(height: 40),
            
            // View Location Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LocationMapScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('View Location'),
              ),
            ),
            
            const Spacer(),
            
            // Footer
            const Center(
              child: Text(
                'Women Only',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 5),
            const Center(
              child: Text(
                'Terms&Condition',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, {Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 15),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourRow(String day, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              time,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
