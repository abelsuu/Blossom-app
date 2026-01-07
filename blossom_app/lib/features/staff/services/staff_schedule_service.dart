import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class StaffScheduleService {
  static final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // --- SHIFTS ---

  /// Get Weekly Shifts Stream
  static Stream<Map<String, dynamic>> getWeeklyShiftsStream(String staffId) {
    return _dbRef.child('staffs/$staffId/shifts').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return {};
      return Map<String, dynamic>.from(data as Map);
    });
  }

  /// Update Weekly Shift for a specific day
  static Future<void> updateDayShift(
    String staffId,
    String day, // 'monday', 'tuesday', etc.
    bool isWorking,
    String startTime,
    String endTime,
  ) async {
    await _dbRef.child('staffs/$staffId/shifts/${day.toLowerCase()}').set({
      'enabled': isWorking,
      'start': startTime,
      'end': endTime,
    });
  }

  // --- TIME OFF ---

  /// Get Time Off Requests Stream
  static Stream<List<Map<String, dynamic>>> getTimeOffStream(String staffId) {
    return _dbRef.child('staffs/$staffId/time_off').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];
      
      final Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> list = [];
      
      map.forEach((key, value) {
        final item = Map<String, dynamic>.from(value as Map);
        item['id'] = key;
        list.add(item);
      });
      
      // Sort by date
      list.sort((a, b) {
        return (a['date'] ?? '').compareTo(b['date'] ?? '');
      });
      
      return list;
    });
  }

  /// Request Time Off
  static Future<void> requestTimeOff(
    String staffId,
    DateTime date,
    String reason,
  ) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    await _dbRef.child('staffs/$staffId/time_off').push().set({
      'date': dateStr,
      'reason': reason,
      'status': 'pending', // pending, approved, rejected
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Delete Time Off Request
  static Future<void> deleteTimeOff(String staffId, String requestId) async {
    await _dbRef.child('staffs/$staffId/time_off/$requestId').remove();
  }

  // --- AVAILABILITY CHECK ---

  /// Check if staff is available (Basic check: Shift + Time Off)
  /// Does NOT check bookings (that's handled by BookingService usually)
  static Future<bool> isStaffScheduled(
    String staffId,
    DateTime date,
    String time,
  ) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final dayName = DateFormat('EEEE').format(date).toLowerCase();

    // 1. Check Time Off
    final timeOffSnap = await _dbRef.child('staffs/$staffId/time_off').get();
    if (timeOffSnap.exists && timeOffSnap.value != null) {
      try {
        final map = timeOffSnap.value as Map;
        for (final val in map.values) {
          final t = Map<String, dynamic>.from(val as Map);
          if (t['date'] == dateStr && t['status'] != 'rejected') {
            return false; // Time off approved or pending
          }
        }
      } catch (e) {
        // Ignore parsing errors
      }
    }

    // 2. Check Weekly Shift
    final shiftSnap = await _dbRef.child('staffs/$staffId/shifts/$dayName').get();
    if (!shiftSnap.exists || shiftSnap.value == null) {
      // Default: Assume 9-5 if not set? Or assume Not Working?
      // Let's assume standard 9-6 for now if not configured, or false.
      // Better to assume false to force configuration.
      return false; 
    }
    
    try {
      final shift = Map<String, dynamic>.from(shiftSnap.value as Map);
      if (shift['enabled'] != true) return false;

      // 3. Check Time Range
      // Simple string comparison for "HH:mm" works if padded (09:00)
      final start = shift['start'] ?? '09:00';
      final end = shift['end'] ?? '17:00';
      
      // Check if time is within start/end
      // E.g. time="10:00", start="09:00", end="17:00"
      // We assume 1-hour slots. So 17:00 is the end of the shift, last slot is 16:00.
      // If end is 17:00, can I book 17:00? No.
      
      return (time.compareTo(start) >= 0 && time.compareTo(end) < 0);
    } catch (e) {
      return false;
    }
  }
}
