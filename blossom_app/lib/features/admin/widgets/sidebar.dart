import 'package:flutter/material.dart';

class SideBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SideBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFFEEE6D3), // Beige background
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo Area
          Column(
            children: [
              Image.asset(
                'assets/images/logo.jpeg',
                height: 80,
                width: 80,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 8),
              Text(
                'BLOSSOM',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                  color: Color(0xFF5D5343),
                ),
              ),
              Text(
                'BEAUTY & WELLNESS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1,
                  color: Color(0xFF5D5343),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),

          // Menu Items
          _buildMenuItem(0, Icons.grid_view, 'Dashboard'),
          _buildMenuItem(1, Icons.calendar_today, 'Bookings'),
          _buildMenuItem(2, Icons.spa, 'Services'),
          _buildMenuItem(3, Icons.person_outline, 'Staff'),
          _buildMenuItem(4, Icons.campaign, 'Marketing'),
          _buildMenuItem(5, Icons.group_outlined, 'Users'),
          _buildMenuItem(6, Icons.settings_outlined, 'Settings'),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5D5343), size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: const Color(0xFF5D5343),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
