import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'bookings_screen.dart';
import 'services_screen.dart';
import 'staff_screen.dart';
import 'marketing_screen.dart';
import 'users_screen.dart';
import 'settings_screen.dart';
import '../widgets/sidebar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const BookingsScreen(),
    const ServicesScreen(),
    const StaffScreen(),
    const MarketingScreen(),
    const UsersScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F2), // Main content background
      body: Row(
        children: [
          SideBar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}
