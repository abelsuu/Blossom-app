import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class StaffService {
  static final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // --- STREAMS ---

  /// Stream for Staff Profile Data
  static Stream<Map<String, dynamic>> getStaffProfileStream(String uid) {
    return _dbRef.child('staffs/$uid').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return {};
      return Map<String, dynamic>.from(data as Map);
    });
  }

  /// Stream for ALL Bookings (for Staff Dashboard)
  static Stream<List<Map<String, dynamic>>> getAllBookingsStream() {
    return _dbRef.child('bookings').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<dynamic, dynamic> bookingsMap = data as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> bookings = [];

      bookingsMap.forEach((key, value) {
        final booking = Map<String, dynamic>.from(value as Map);
        booking['id'] = key;
        bookings.add(booking);
      });

      // Sort by date (ascending)
      bookings.sort((a, b) {
        try {
          final dateA = DateFormat('yyyy-MM-dd').parse(a['date']);
          final dateB = DateFormat('yyyy-MM-dd').parse(b['date']);
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });

      return bookings;
    });
  }

  // --- ACTIONS ---

  /// Update Booking Status
  static Future<void> updateBookingStatus(
    String bookingId,
    String newStatus,
  ) async {
    final bookingRef = _dbRef.child('bookings/$bookingId');

    // Normalize status to ensure consistency
    String normalizedStatus = newStatus.toLowerCase();
    if (normalizedStatus == 'complete') normalizedStatus = 'completed';
    if (normalizedStatus == 'confirm') normalizedStatus = 'confirmed';
    if (normalizedStatus == 'cancel') normalizedStatus = 'cancelled';

    final Map<String, dynamic> updates = {'status': normalizedStatus};

    // If confirming, record the staff member AND send notification
    if (normalizedStatus == 'confirmed') {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final staffSnapshot = await _dbRef.child('staffs/${user.uid}').get();
          if (staffSnapshot.exists) {
            final staffData = Map<String, dynamic>.from(
              staffSnapshot.value as Map,
            );
            final staffName = staffData['name'] ?? 'Unknown Staff';
            updates['staff'] = staffName;
            updates['confirmedBy'] = staffName; // Added for Admin visibility
          }
        }

        // Send Notification
        final snapshot = await bookingRef.get();
        if (snapshot.exists) {
          final booking = Map<String, dynamic>.from(snapshot.value as Map);
          final uid = booking['userId'];
          if (uid != null) {
            String friendlyDate = booking['date']?.toString() ?? '';
            try {
              final parsed = DateFormat('yyyy-MM-dd').parse(friendlyDate);
              friendlyDate = DateFormat('EEEE, d MMMM').format(parsed);
            } catch (_) {}
            final friendlyTime = booking['time']?.toString() ?? '';

            await _dbRef.child('notifications/$uid').push().set({
              'message':
                  'Your appointment on $friendlyDate at $friendlyTime has been confirmed!',
              'timestamp': ServerValue.timestamp,
              'type': 'booking_confirmed',
              'bookingId': bookingId,
              'date': booking['date'],
              'time': booking['time'],
            });
          }
        }
      } catch (e) {
        debugPrint('Error handling confirmation: $e');
      }
    }

    // If cancelled, record who cancelled it
    if (normalizedStatus == 'cancelled') {
      updates['cancelledBy'] = 'staff';
      updates['cancellationReason'] = 'Cancelled by staff';
    }

    await bookingRef.update(updates);

    // If cancelled, send notification to User AND free up availability
    if (normalizedStatus == 'cancelled') {
      try {
        final snapshot = await bookingRef.get();
        if (snapshot.exists) {
          final booking = Map<String, dynamic>.from(snapshot.value as Map);

          // Free availability
          final date = booking['date'];
          final time = booking['time'];
          if (date != null && time != null) {
            final safeTime = time.toString().replaceAll('.', ':');
            await _dbRef.child('availability/$date/$safeTime').remove();
          }

          final uid = booking['userId'];
          if (uid != null) {
            String friendlyDate = booking['date']?.toString() ?? '';
            try {
              final parsed = DateFormat('yyyy-MM-dd').parse(friendlyDate);
              friendlyDate = DateFormat('EEEE, d MMMM').format(parsed);
            } catch (_) {}
            final friendlyTime = booking['time']?.toString() ?? '';

            await _dbRef.child('notifications/$uid').push().set({
              'message':
                  'Your appointment on $friendlyDate at $friendlyTime has been cancelled.',
              'timestamp': ServerValue.timestamp,
              'type': 'booking_cancelled',
              'bookingId': bookingId,
              'date': booking['date'],
              'time': booking['time'],
            });
          }
        }
      } catch (e) {
        debugPrint('Error sending cancellation notification: $e');
      }
    }

    // Award loyalty points if completed and not already awarded
    // User Requirement: Trigger only on "Complete" (which matches 'completed' in our enum/dropdown)
    if (normalizedStatus == 'completed') {
      try {
        // Record who completed it
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final staffSnapshot = await _dbRef.child('staffs/${user.uid}').get();
          if (staffSnapshot.exists) {
            final staffData = Map<String, dynamic>.from(
              staffSnapshot.value as Map,
            );
            final staffName = staffData['name'] ?? 'Unknown Staff';
            updates['completedBy'] = staffName; // Added for Admin visibility
          }
        }

        final snapshot = await bookingRef.get();
        if (snapshot.exists) {
          final booking = Map<String, dynamic>.from(snapshot.value as Map);

          // 1. Calculate and Update Total Price
          double totalPrice = 0.0;
          if (booking.containsKey('services') && booking['services'] is List) {
            final servicesList = booking['services'] as List;
            // Fetch catalog to get prices - updated to use service_catalog
            final catalogSnapshot = await _dbRef.child('service_catalog').get();
            final Map<String, double> priceMap = {};

            if (catalogSnapshot.exists && catalogSnapshot.value is Map) {
              final catalogData = catalogSnapshot.value as Map;
              // Flatten the category structure (Body, Facials, etc.)
              catalogData.forEach((key, value) {
                if (value is Map) {
                  // This is likely a category (e.g., "Body") containing services
                  value.forEach((serviceKey, serviceData) {
                    if (serviceData is Map) {
                      final title =
                          serviceData['title']?.toString() ??
                          serviceData['name']?.toString() ??
                          '';
                      final priceStr = serviceData['price']?.toString() ?? '0';
                      // Parse "Rm 130.00" -> 130.0 or "130" -> 130.0
                      final price =
                          double.tryParse(
                            priceStr.replaceAll(RegExp(r'[^0-9.]'), ''),
                          ) ??
                          0.0;
                      if (title.isNotEmpty) {
                        priceMap[title] = price;
                      }
                    }
                  });
                } else if (value is List) {
                  // Handle list-based categories if any (legacy structure)
                  for (var item in value) {
                    if (item is Map) {
                      final title = item['title']?.toString() ?? '';
                      final priceStr = item['price']?.toString() ?? '0';
                      final price =
                          double.tryParse(
                            priceStr.replaceAll(RegExp(r'[^0-9.]'), ''),
                          ) ??
                          0.0;
                      priceMap[title] = price;
                    }
                  }
                }
              });
            }

            // Fallback to hardcoded prices if DB is empty (using common items from CatalogService)
            if (priceMap.isEmpty) {
              priceMap.addAll({
                'Body Massage': 130.0,
                'Milk Bath': 70.0,
                'Body Scrub': 80.0,
                'Whitening Body Mask': 100.0,
                'Herbal Sauna': 50.0,
                'Flower Bath': 65.0,
                'Signature Facial': 150.0,
                'Lifting Facial': 170.0,
                'Collagen Facial': 180.0,
                'Whitening Facial': 140.0,
                'Hydrating Facial': 160.0,
                'Acne Treatment': 120.0,
                'Manicure': 50.0,
                'Pedicure': 60.0,
                'Gel Polish': 80.0,
                'Nail Art': 100.0,
              });
            }

            for (var serviceName in servicesList) {
              totalPrice += priceMap[serviceName.toString()] ?? 0.0;
            }
          }

          // Update booking with total price
          await bookingRef.update({'totalPrice': totalPrice});

          // 2. Award Points
          if (booking['pointsAwarded'] != true) {
            final userId = booking['userId'];
            if (userId != null) {
              // Calculate points (Fixed 5 points per booking as per new requirement)
              int pointsToAward = 5;

              // Legacy logic commented out:
              /*
              if (booking.containsKey('services') &&
                  booking['services'] is List) {
                final services = booking['services'] as List;
                pointsToAward = services.length * 5;
              } else if (booking.containsKey('request') &&
                  booking['request'] != null) {
                // Fallback for single service request
                pointsToAward = 5;
              }
              */

              if (pointsToAward > 0) {
                final loyaltyRef = _dbRef.child('users/$userId/loyalty');
                final loyaltySnapshot = await loyaltyRef.get();
                int currentPoints = 0;
                String currentTier = 'Bronze';
                int currentVouchers = 0;
                if (loyaltySnapshot.exists) {
                  final loyaltyData = Map<String, dynamic>.from(
                    loyaltySnapshot.value as Map,
                  );
                  currentPoints = loyaltyData['points'] as int? ?? 0;
                  currentTier = (loyaltyData['tier'] as String?) ?? 'Bronze';
                  currentVouchers = loyaltyData['vouchers'] as int? ?? 0;
                }

                // Update points
                await loyaltyRef.update({
                  'points': currentPoints + pointsToAward,
                });

                // Add to history
                final historyRef = loyaltyRef.child('history').push();
                await historyRef.set({
                  'type': 'earned',
                  'amount': pointsToAward,
                  'date': ServerValue.timestamp,
                  'description': 'Completed Service(s)',
                  'bookingId': bookingId,
                });

                // Mark booking as points awarded
                await bookingRef.update({'pointsAwarded': true});

                final newPoints = currentPoints + pointsToAward;
                String newTier;
                if (newPoints >= 150) {
                  newTier = 'Gold';
                } else if (newPoints >= 50) {
                  newTier = 'Silver';
                } else {
                  newTier = 'Bronze';
                }
                if (newTier != currentTier) {
                  await loyaltyRef.update({'tier': newTier});
                  await loyaltyRef.update({'vouchers': currentVouchers + 1});
                  final h2 = loyaltyRef.child('history').push();
                  await h2.set({
                    'type': 'earned',
                    'amount': 1,
                    'date': ServerValue.timestamp,
                    'description': 'Tier upgrade voucher',
                  });
                }
              }
            }
          }
        }
      } catch (e) {
        // Log error but don't crash status update
        debugPrint('Error awarding points: $e');
      }
    }
  }

  /// Update Booking Service
  static Future<void> updateBookingService(
    String bookingId,
    String newService,
  ) async {
    await _dbRef.child('bookings/$bookingId').update({'request': newService});
  }

  /// Update Booking Services (multiple)
  static Future<void> updateBookingServices(
    String bookingId,
    List<String> services,
  ) async {
    await _dbRef.child('bookings/$bookingId').update({'services': services});
  }

  // --- NOTES ---

  /// Get Stream of ALL Notes from ALL Bookings
  static Stream<List<Map<String, dynamic>>> getAllNotesStream() {
    return _dbRef.child('bookings').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<dynamic, dynamic> bookingsMap = data as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> allNotes = [];

      bookingsMap.forEach((bookingId, bookingData) {
        final booking = Map<String, dynamic>.from(bookingData as Map);
        if (booking.containsKey('notes')) {
          final notesMap = booking['notes'] as Map<dynamic, dynamic>;
          notesMap.forEach((noteId, noteData) {
            final note = Map<String, dynamic>.from(noteData as Map);
            note['id'] = noteId;
            note['bookingId'] = bookingId;
            // Use customerName from note if available, otherwise fallback to booking's userName
            note['customerName'] =
                note['customerName'] ?? booking['userName'] ?? 'Unknown';
            allNotes.add(note);
          });
        }
      });

      // Sort by timestamp (newest first)
      allNotes.sort((a, b) {
        final tA = a['timestamp'] as int? ?? 0;
        final tB = b['timestamp'] as int? ?? 0;
        return tB.compareTo(tA);
      });

      return allNotes;
    });
  }

  /// Get Notes Stream for a Booking
  static Stream<List<Map<String, dynamic>>> getBookingNotesStream(
    String bookingId,
  ) {
    return _dbRef.child('bookings/$bookingId/notes').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<dynamic, dynamic> notesMap = data as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> notes = [];

      notesMap.forEach((key, value) {
        notes.add({'id': key, ...Map<String, dynamic>.from(value as Map)});
      });

      // Sort by timestamp (newest first)
      notes.sort((a, b) {
        final tA = a['timestamp'] as int? ?? 0;
        final tB = b['timestamp'] as int? ?? 0;
        return tB.compareTo(tA);
      });

      return notes;
    });
  }

  /// Add a Note to a Booking
  static Future<void> addBookingNote(
    String bookingId,
    String content, {
    String? customerName,
  }) async {
    final noteRef = _dbRef.child('bookings/$bookingId/notes').push();
    await noteRef.set({
      'content': content,
      'timestamp': ServerValue.timestamp,
      'customerName': customerName,
    });
  }

  /// Update a Note
  static Future<void> updateBookingNote(
    String bookingId,
    String noteId,
    String content,
  ) async {
    await _dbRef.child('bookings/$bookingId/notes/$noteId').update({
      'content': content,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Delete a Note
  static Future<void> deleteBookingNote(String bookingId, String noteId) async {
    await _dbRef.child('bookings/$bookingId/notes/$noteId').remove();
  }

  // --- PERSONAL NOTES ---

  /// Get Personal Notes Stream
  static Stream<List<Map<String, dynamic>>> getPersonalNotesStream(String uid) {
    return _dbRef.child('staffs/$uid/personal_notes').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<dynamic, dynamic> notesMap = data as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> notes = [];

      notesMap.forEach((key, value) {
        notes.add({'id': key, ...Map<String, dynamic>.from(value as Map)});
      });

      // Sort by timestamp (newest first)
      notes.sort((a, b) {
        final tA = a['timestamp'] as int? ?? 0;
        final tB = b['timestamp'] as int? ?? 0;
        return tB.compareTo(tA);
      });

      return notes;
    });
  }

  /// Add a Personal Note
  static Future<void> addPersonalNote(String uid, String content) async {
    final noteRef = _dbRef.child('staffs/$uid/personal_notes').push();
    await noteRef.set({'content': content, 'timestamp': ServerValue.timestamp});
  }

  /// Update a Personal Note
  static Future<void> updatePersonalNote(
    String uid,
    String noteId,
    String content,
  ) async {
    await _dbRef.child('staffs/$uid/personal_notes/$noteId').update({
      'content': content,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Delete a Personal Note
  static Future<void> deletePersonalNote(String uid, String noteId) async {
    await _dbRef.child('staffs/$uid/personal_notes/$noteId').remove();
  }

  // --- STAFF PROFILE ---

  /// Update Staff Profile
  static Future<void> updateStaffProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    // Ensure 'name' is updated for Admin visibility if firstName/lastName are present
    if (data.containsKey('firstName') && data.containsKey('lastName')) {
      data['name'] = '${data['firstName']} ${data['lastName']}';
    }
    await _dbRef.child('staffs/$uid').update(data);
  }

  // --- ADMIN / DEBUG ---

  /// Reset ALL Users' Loyalty Points to 0 (Debug Feature)
  static Future<void> resetAllUsersLoyalty() async {
    try {
      final snapshot = await _dbRef.child('users').get();
      if (snapshot.exists) {
        final users = Map<String, dynamic>.from(snapshot.value as Map);
        for (final key in users.keys) {
          await _dbRef.child('users/$key/loyalty').update({
            'points': 0,
            'vouchers': 0,
          });
          // Optional: Clear history too
          await _dbRef.child('users/$key/loyalty/history').remove();
        }
      }
    } catch (e) {
      debugPrint('Error resetting all loyalty points: $e');
      rethrow;
    }
  }
}
