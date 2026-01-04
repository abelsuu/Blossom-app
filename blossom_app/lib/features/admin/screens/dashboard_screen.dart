import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D5343),
                    ),
                  ),
                  Text(
                    'Welcome back Admin 1',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              // Profile Dropdown
              PopupMenuButton<String>(
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) async {
                  if (value == 'logout') {
                    // Sign out and navigate to Onboarding
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5D5343),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Admin',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance.ref('bookings').onValue,
                  builder: (context, snapshot) {
                    int count = 0;
                    if (snapshot.hasData) {
                      final data = snapshot.data!.snapshot.value;
                      if (data is Map) count = data.length;
                    }
                    return _buildStatCard(
                      'Total Bookings',
                      count.toString(),
                      '',
                      Icons.calendar_today,
                      Colors.orange.shade100,
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance.ref('bookings').onValue,
                  builder: (context, snapshot) {
                    double totalEarnings = 0.0;
                    if (snapshot.hasData &&
                        snapshot.data!.snapshot.value is Map) {
                      final data = snapshot.data!.snapshot.value as Map;
                      data.forEach((key, value) {
                        if (value is Map) {
                          final status = (value['status'] ?? '')
                              .toString()
                              .toLowerCase();
                          if (status == 'completed' || status == 'complete') {
                            // Use stored totalPrice if available
                            if (value.containsKey('totalPrice')) {
                              totalEarnings += (value['totalPrice'] as num)
                                  .toDouble();
                            }
                          }
                        }
                      });
                    }
                    return _buildStatCard(
                      'Total Earnings',
                      'Rm ${totalEarnings.toStringAsFixed(2)}',
                      '',
                      Icons.account_balance_wallet,
                      Colors.green.shade100,
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance.ref('staffs').onValue,
                  builder: (context, snapshot) {
                    int active = 0;
                    if (snapshot.hasData) {
                      final data = snapshot.data!.snapshot.value;
                      if (data is Map) {
                        data.forEach((k, v) {
                          if (v is Map) {
                            final status = (v['status'] ?? '')
                                .toString()
                                .toLowerCase();
                            if (status == 'active') active++;
                          }
                        });
                      }
                    }
                    return _buildStatCard(
                      'Active Staff',
                      active.toString(),
                      '',
                      Icons.person,
                      Colors.blue.shade100,
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance
                      .ref('service_catalog')
                      .onValue,
                  builder: (context, snapshot) {
                    int total = 0;
                    int categories = 0;
                    if (snapshot.hasData) {
                      final data = snapshot.data!.snapshot.value;
                      if (data is Map) {
                        categories = data.length;
                        data.forEach((cat, items) {
                          if (items is List) {
                            total += items.length;
                          } else if (items is Map) {
                            total += items.length;
                          }
                        });
                      }
                    }
                    return _buildStatCard(
                      'Total Services',
                      total.toString(),
                      '$categories Categories',
                      Icons.spa,
                      Colors.red.shade100,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Recent Bookings Table
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Bookings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D5343),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<DatabaseEvent>(
                      stream: FirebaseDatabase.instance.ref('bookings').onValue,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF5D5343),
                            ),
                          );
                        }
                        final data = snapshot.data?.snapshot.value;
                        final List<Map<String, dynamic>> bookings = [];
                        if (data is Map) {
                          data.forEach((key, value) {
                            final m = Map<String, dynamic>.from(value as Map);
                            bookings.add(m);
                          });
                        }
                        bookings.sort((a, b) {
                          final ta = a['timestamp'] ?? 0;
                          final tb = b['timestamp'] ?? 0;
                          return (tb as int).compareTo(ta as int);
                        });
                        final rows = bookings.take(8).toList();
                        return ListView(
                          children: [
                            _buildTableHeader(),
                            const Divider(),
                            for (final b in rows) ...[
                              _buildTableRow(
                                (b['customerName'] ??
                                        b['userName'] ??
                                        'Unknown')
                                    .toString(),
                                (() {
                                  final services = b['services'];
                                  if (services is List) {
                                    return services.whereType<String>().join(
                                      ', ',
                                    );
                                  }
                                  return (b['service'] ?? '').toString();
                                })(),
                                '${(b['date'] ?? '').toString()} ${b['time'] ?? ''}',
                                (b['staff'] ?? '').toString(),
                                (b['status'] ?? 'Pending').toString(),
                                Colors.green,
                              ),
                              const Divider(),
                            ],
                          ],
                        );
                      },
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

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color iconBgColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D5343),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[600],
              ), // Assuming positive growth
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: const [
          Expanded(
            flex: 2,
            child: Text(
              'Customer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Service',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Date - Time',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('Staff', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    String customer,
    String service,
    String dateTime,
    String staff,
    String status,
    Color statusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(customer)),
          Expanded(flex: 2, child: Text(service)),
          Expanded(flex: 3, child: Text(dateTime)),
          Expanded(flex: 2, child: Text(staff)),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
