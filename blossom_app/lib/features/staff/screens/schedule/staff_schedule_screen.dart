import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blossom_app/features/staff/services/staff_schedule_service.dart';

class StaffScheduleScreen extends StatefulWidget {
  const StaffScheduleScreen({super.key});

  @override
  State<StaffScheduleScreen> createState() => _StaffScheduleScreenState();
}

class _StaffScheduleScreenState extends State<StaffScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Schedule',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF5D5343),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFD4AF37),
          tabs: const [
            Tab(text: 'Weekly Shifts'),
            Tab(text: 'Time Off'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildShiftsTab(), _buildTimeOffTab()],
      ),
    );
  }

  // --- SHIFTS TAB ---

  Widget _buildShiftsTab() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: StaffScheduleService.getWeeklyShiftsStream(_uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final shifts = snapshot.data ?? {};

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _days.length,
          itemBuilder: (context, index) {
            final day = _days[index];
            final key = day.toLowerCase();
            final data = shifts[key] as Map?;

            final bool isWorking = data?['enabled'] ?? false;
            final String start = data?['start'] ?? '09:00';
            final String end = data?['end'] ?? '18:00';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          day,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Switch(
                          value: isWorking,
                          activeTrackColor: const Color(0xFFD4AF37),
                          onChanged: (val) async {
                            // Optimistically update or just wait for stream?
                            // Stream should be fast, but let's ensure it calls the service.
                            try {
                              await StaffScheduleService.updateDayShift(
                                _uid,
                                day,
                                val,
                                start,
                                end,
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error updating schedule: $e')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    if (isWorking) ...[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTimePickerButton(context, 'Start', start, (
                            newTime,
                          ) {
                            StaffScheduleService.updateDayShift(
                              _uid,
                              day,
                              true,
                              newTime,
                              end,
                            );
                          }),
                          const Text('to'),
                          _buildTimePickerButton(context, 'End', end, (
                            newTime,
                          ) {
                            StaffScheduleService.updateDayShift(
                              _uid,
                              day,
                              true,
                              start,
                              newTime,
                            );
                          }),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimePickerButton(
    BuildContext context,
    String label,
    String currentTime,
    Function(String) onSelected,
  ) {
    return TextButton(
      onPressed: () async {
        final parts = currentTime.split(':');
        final time = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );

        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );

        if (picked != null) {
          final h = picked.hour.toString().padLeft(2, '0');
          final m = picked.minute.toString().padLeft(2, '0');
          onSelected('$h:$m');
        }
      },
      child: Text(
        currentTime,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5D5343),
        ),
      ),
    );
  }

  // --- TIME OFF TAB ---

  Widget _buildTimeOffTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: StaffScheduleService.getTimeOffStream(_uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return const Center(child: Text('No time off requests.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.event_busy, color: Colors.red),
                      title: Text(item['date'] ?? ''),
                      subtitle: Text(item['reason'] ?? 'No reason'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () {
                          StaffScheduleService.deleteTimeOff(_uid, item['id']);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showAddTimeOffDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D5343),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                'Request Time Off',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddTimeOffDialog() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final controller = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reason for Time Off'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'e.g. Sick Leave, Vacation',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                StaffScheduleService.requestTimeOff(
                  _uid,
                  pickedDate,
                  controller.text,
                );
                Navigator.pop(context);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      );
    }
  }
}
