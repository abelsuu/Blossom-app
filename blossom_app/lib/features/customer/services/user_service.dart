import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // --- STREAMS ---

  /// Stream for User Profile Data (Name, Age, Skin Stats, etc.)
  static Stream<Map<String, dynamic>> getUserProfileStream(String uid) {
    final query = _dbRef.child('users/$uid/profile');
    if (!kIsWeb) {
      query.keepSynced(true);
    }
    return query.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return {};
      return Map<String, dynamic>.from(data as Map);
    });
  }

  /// Stream for Loyalty Data (Points, Vouchers)
  static Stream<Map<String, dynamic>> getLoyaltyStream(String uid) {
    final query = _dbRef.child('users/$uid/loyalty');
    if (!kIsWeb) {
      query.keepSynced(true);
    }
    return query.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return {'points': 0, 'vouchers': 0};
      return Map<String, dynamic>.from(data as Map);
    });
  }

  /// Stream for Loyalty History
  static Stream<List<Map<String, dynamic>>> getLoyaltyHistoryStream(
    String uid,
  ) {
    final query = _dbRef.child('users/$uid/loyalty/history');
    if (!kIsWeb) {
      query.keepSynced(true);
    }
    return query.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<dynamic, dynamic> historyMap = data as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> history = [];

      historyMap.forEach((key, value) {
        history.add({'id': key, ...Map<String, dynamic>.from(value as Map)});
      });

      // Sort by date (newest first)
      history.sort((a, b) {
        final tA = a['date'] as int? ?? 0;
        final tB = b['date'] as int? ?? 0;
        return tB.compareTo(tA);
      });

      return history;
    });
  }

  /// Stream for the Next Upcoming Appointment
  static Stream<Map<String, dynamic>?> getNextAppointmentStream(String uid) {
    // Client-side filtering for robustness (avoiding missing server-side index issues)
    final query = _dbRef.child('bookings');
    if (!kIsWeb) {
      query.keepSynced(true);
    }

    return query.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) {
        debugPrint('UserService: No bookings found in DB');
        return null;
      }

      final Map<dynamic, dynamic> bookingsMap = data as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> bookings = [];

      debugPrint(
        'UserService: Scanning ${bookingsMap.length} total bookings in DB...',
      );

      bookingsMap.forEach((key, value) {
        final booking = Map<String, dynamic>.from(value as Map);
        final bookingUserId = booking['userId'];

        // Debugging ID mismatch
        if (bookingUserId == uid) {
          bookings.add({...booking, 'id': key});
        } else {
          // debugPrint('UserService: Skipping booking $key (User: $bookingUserId != Current: $uid)');
        }
      });

      debugPrint(
        'UserService: Found ${bookings.length} bookings for user $uid',
      );

      // Filter for upcoming dates AND times
      final now = DateTime.now();
      // Reset to beginning of today for date comparison fallback
      final today = DateTime(now.year, now.month, now.day);

      final upcoming = bookings.where((b) {
        try {
          final dateStr = b['date'] as String; // yyyy-MM-dd
          final timeStr = b['time'] as String; // H:mm (e.g., "9:00" or "1:00")

          // Parse Date
          final dateParts = dateStr.split('-');
          final year = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final day = int.parse(dateParts[2]);

          // Parse Time
          final timeParts = timeStr.split(':');
          var hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);

          // Adjust hour for PM (1:00 - 6:00 are PM)
          // Heuristic: If hour is small (1-6) and it's a typical business, treat as PM
          if (hour < 7) {
            hour += 12; // Convert 1:00 -> 13:00
          }

          final bookingDateTime = DateTime(year, month, day, hour, minute);

          debugPrint(
            'UserService: Checking booking $dateStr $timeStr -> $bookingDateTime vs Now $now',
          );

          // Check if strictly after now
          return bookingDateTime.isAfter(now);
        } catch (e) {
          debugPrint('UserService: Error parsing booking: $e');
          // If parsing fails, fall back to date-only check (legacy)
          try {
            final dateStr = b['date'] as String;
            final bookingDate = DateTime.parse(dateStr);
            // Use today variable created above
            return bookingDate.isAfter(today) ||
                bookingDate.isAtSameMomentAs(today);
          } catch (_) {
            return false;
          }
        }
      }).toList();

      debugPrint('UserService: Found ${upcoming.length} upcoming bookings');

      if (upcoming.isEmpty) return null;

      // Sort by full DateTime
      upcoming.sort((a, b) {
        try {
          // Helper to parse full DateTime for sorting
          DateTime parseDT(Map<String, dynamic> m) {
            final dateStr = m['date'] as String;
            final timeStr = m['time'] as String;
            final dateParts = dateStr.split('-');
            final timeParts = timeStr.split(':');
            var hour = int.parse(timeParts[0]);
            if (hour < 7) hour += 12;
            return DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
              hour,
              int.parse(timeParts[1]),
            );
          }

          final dtA = parseDT(a);
          final dtB = parseDT(b);
          return dtA.compareTo(dtB);
        } catch (e) {
          // Fallback sort by date string
          final dateA = a['date'] as String;
          final dateB = b['date'] as String;
          return dateA.compareTo(dateB);
        }
      });

      return upcoming.first;
    });
  }

  /// Update User Profile Data
  static Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _dbRef.child('users/$uid/profile').update(data);
  }

  /// Reset Loyalty Data (Points & Vouchers) to 0
  static Future<void> resetLoyaltyData(String uid) async {
    await _dbRef.child('users/$uid/loyalty').set({
      'points': 0,
      'vouchers': 0,
      'isVerified': true,
    });
  }

  // --- SEEDING ---

  /// Check if user data exists; if not, seed default data matching the design.
  static Future<void> checkAndSeedUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final userRef = _dbRef.child('users/$uid');

    try {
      // Reduced timeout to 5s to fail faster if offline,
      // but catch the error so it doesn't crash the app flow.
      final snapshot = await userRef.get().timeout(const Duration(seconds: 5));

      if (!snapshot.exists) {
        debugPrint('Seeding default user data for $uid...');

        // Seed Profile
        await userRef.child('profile').set({
          'firstName': user.displayName?.split(' ').first ?? 'Guest',
          'lastName': user.displayName?.split(' ').last ?? '',
          // 'age': null, // Age should be set by user
          'skinType': 'Unknown', // Default to Unknown or similar
          'sensitivity': 'Unknown',
          'elasticity': 'Unknown',
          'acneProne': 'Unknown',
        });

        // Seed Loyalty
        await userRef.child('loyalty').set({
          'points': 0,
          'vouchers': 0, // Also set vouchers to 0 for new user
          'isVerified': true,
        });
      }
    } catch (e) {
      debugPrint(
        'Error checking/seeding user data (likely offline or slow connection): $e',
      );
      // Do not rethrow; app should continue functioning even if seeding fails temporarily.
    }
  }

  // --- SKIN ANALYSIS LIMITS ---

  /// Check if user can perform skin analysis (max 3 per month)
  /// Uses SharedPreferences as primary source for instant checking and offline support.
  static Future<bool> canAnalyzeSkin(String uid) async {
    final now = DateTime.now();
    final currentMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    final prefs = await SharedPreferences.getInstance();

    // 1. Check Local Cache (Fast & Robust)
    final cachedMonth = prefs.getString('skin_analysis_month_v3_$uid');
    final cachedCount = prefs.getInt('skin_analysis_count_v3_$uid') ?? 0;

    if (cachedMonth == currentMonth) {
      if (cachedCount >= 3) {
        return false;
      }
    } else {
      // New month locally? Reset local cache
      await prefs.setString('skin_analysis_month_v3_$uid', currentMonth);
      await prefs.setInt('skin_analysis_count_v3_$uid', 0);
    }

    // 2. Try Firebase Sync (Best Effort)
    // If local check passed, we double check with Firebase if possible,
    // but if it fails/times out, we trust the local "true" result (Fail Open-ish, but grounded in local state).
    // If local said "false", we return false immediately above.
    try {
      final snapshot = await _dbRef
          .child('users/$uid/skin_analysis_usage_v3')
          .get()
          .timeout(const Duration(seconds: 15)); // Increased timeout to 15s

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        if (data['month'] == currentMonth) {
          final serverCount = data['count'] ?? 0;
          // Sync local with server if server is ahead
          if (serverCount > cachedCount) {
            await prefs.setInt('skin_analysis_count_v3_$uid', serverCount);
            if (serverCount >= 3) return false;
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking skin analysis limit (Firebase): $e');
      // Ignore Firebase error, proceed with local decision (which is likely true if we got here)
    }

    return true;
  }

  /// Increment skin analysis usage count
  static Future<void> incrementSkinAnalysisUsage(String uid) async {
    final now = DateTime.now();
    final currentMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    final prefs = await SharedPreferences.getInstance();

    // 1. Update Local Cache Immediately
    final cachedMonth = prefs.getString('skin_analysis_month_v3_$uid');
    int currentCount = prefs.getInt('skin_analysis_count_v3_$uid') ?? 0;

    if (cachedMonth != currentMonth) {
      currentCount = 1;
      await prefs.setString('skin_analysis_month_v3_$uid', currentMonth);
    } else {
      currentCount++;
    }
    await prefs.setInt('skin_analysis_count_v3_$uid', currentCount);

    // 2. Update Firebase (Background / Best Effort)
    // We don't await this to avoid blocking the UI if network is slow.
    _updateFirebaseUsage(uid, currentMonth).ignore();
  }

  static Future<void> _updateFirebaseUsage(
    String uid,
    String currentMonth,
  ) async {
    final ref = _dbRef.child('users/$uid/skin_analysis_usage_v3');
    try {
      final snapshot = await ref.get().timeout(const Duration(seconds: 5));

      if (!snapshot.exists) {
        await ref.set({'month': currentMonth, 'count': 1});
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      if (data['month'] != currentMonth) {
        // Reset for new month
        await ref.set({'month': currentMonth, 'count': 1});
      } else {
        // Increment
        await ref.update({'count': (data['count'] ?? 0) + 1});
      }
    } catch (e) {
      debugPrint('Error incrementing skin analysis usage (background): $e');
    }
  }

  /// Get remaining skin analysis count for the month
  static Future<int> getRemainingSkinAnalysisCount(String uid) async {
    final now = DateTime.now();
    final currentMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    final prefs = await SharedPreferences.getInstance();

    // Prefer local cache for UI display
    final cachedMonth = prefs.getString('skin_analysis_month_v3_$uid');
    if (cachedMonth == currentMonth) {
      final cachedCount = prefs.getInt('skin_analysis_count_v3_$uid') ?? 0;
      return (3 - cachedCount).clamp(0, 3);
    }

    return 3;
  }

  /// Reset skin analysis limit (Debug/Testing only)
  static Future<void> resetSkinAnalysisLimit(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('skin_analysis_count_v3_$uid', 0);

    // Also reset in Firebase
    try {
      await _dbRef.child('users/$uid/skin_analysis_usage_v3').update({
        'count': 0,
      });
    } catch (e) {
      debugPrint('Error resetting skin analysis limit: $e');
    }
  }

  // --- SKIN ANALYSIS HISTORY ---

  /// Save Skin Analysis Result and Update Profile
  static Future<void> saveSkinAnalysisResult(
    String uid,
    Map<String, dynamic> result,
  ) async {
    final timestamp = DateTime.now().toIso8601String();

    try {
      // 1. Save to History
      await _dbRef.child('users/$uid/skin_analysis_history').push().set({
        'timestamp': timestamp,
        'result': result,
      });

      // 2. Update Profile Stats
      // Map AI results to Profile fields
      final metrics = result['metrics'] as Map<String, dynamic>? ?? {};
      final profileUpdates = <String, dynamic>{
        'skinType': result['skinType'] ?? 'Unknown',
        'acneProne': metrics['acne']?['value'] ?? 'Unknown',
        'sensitivity': metrics['sensitivity']?['value'] ?? 'Unknown',
        'elasticity': metrics['elasticity']?['value'] ?? 'Unknown',
        'lastAnalysisDate': timestamp,
      };

      await _dbRef.child('users/$uid/profile').update(profileUpdates);
    } catch (e) {
      debugPrint('Error saving skin analysis (background): $e');
      rethrow; // Allow UI to handle error
    }
  }

  /// Helper to deeply convert Map<dynamic, dynamic> to Map<String, dynamic>
  static Map<String, dynamic> _deepMapConvert(Map<dynamic, dynamic> map) {
    final converted = <String, dynamic>{};
    map.forEach((key, value) {
      if (value is Map) {
        converted[key.toString()] = _deepMapConvert(
          value as Map<dynamic, dynamic>,
        );
      } else if (value is List) {
        converted[key.toString()] = value.map((e) {
          if (e is Map) return _deepMapConvert(e as Map<dynamic, dynamic>);
          return e;
        }).toList();
      } else {
        converted[key.toString()] = value;
      }
    });
    return converted;
  }

  /// Get Skin Analysis History Stream
  static Stream<List<Map<String, dynamic>>> getSkinAnalysisHistoryStream(
    String uid,
  ) {
    debugPrint('Initializing history stream for user: $uid');
    return _dbRef.child('users/$uid/skin_analysis_history').onValue.map((
      event,
    ) {
      final data = event.snapshot.value;
      debugPrint('History stream event received. Data exists: ${data != null}');

      if (data == null) return [];

      final Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> history = [];

      map.forEach((key, value) {
        if (value is Map) {
          final convertedValue = _deepMapConvert(
            value as Map<dynamic, dynamic>,
          );
          history.add({'id': key, ...convertedValue});
        }
      });

      // Sort by timestamp descending (newest first)
      history.sort((a, b) {
        final tA = a['timestamp'] as String;
        final tB = b['timestamp'] as String;
        return tB.compareTo(tA);
      });

      return history;
    });
  }
}
