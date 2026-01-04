import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:blossom_app/core/constants/promotions_data.dart';

class PromotionsService {
  static final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  static const List<Map<String, dynamic>> _fallbackPromotions = [
    {
      'title': 'Christmas Deals is\nOngoing !!',
      'subtitle': 'Get free gift for every\ntreatment',
      'imageUrl':
          'https://images.unsplash.com/photo-1544717305-2782549b5136?q=80&w=200',
      'color': 0xFF556B2F, // Olive Green
      'textColor': 0xFFFFFFFF,
      'pillColor': 0xCCFFFFFF,
    },
    {
      'title': 'Bring Your Friend or\nFamily',
      'subtitle': 'Get 20% discount',
      'imageUrl':
          'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?q=80&w=200',
      'color': 0xFFCFA6A6, // Dusty Rose
      'textColor': 0xFFFFFFFF,
      'pillColor': 0xCCFFFFFF,
    },
    {
      'title': 'New User Promo',
      'subtitle': 'First treatment 50% off',
      'imageUrl':
          'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?q=80&w=200',
      'color': 0xFFFFDAB9, // Peach Puff
      'textColor': 0xFF000000,
      'pillColor': 0x99FFFFFF,
    },
  ];

  static List<Map<String, dynamic>> getFallbackPromotions() {
    return _fallbackPromotions;
  }

  // Stream of promotions list
  static Stream<List<Map<String, dynamic>>> getPromotionsStream() {
    final query = _dbRef.child('promotions');
    if (!kIsWeb) {
      query.keepSynced(true);
    }
    return query.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return []; // Return empty if null (Realtime DB state)

      try {
        List<Map<String, dynamic>> out = [];
        if (data is List) {
          out = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else if (data is Map) {
          out = data.values
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        return out; // Return actual data
      } catch (e) {
        debugPrint('Error parsing promotions: $e');
        return [];
      }
    });
  }

  // Add a new promotion
  static Future<void> addPromotion(Map<String, dynamic> promo) async {
    final newRef = _dbRef.child('promotions').push();
    promo['id'] = newRef.key;
    await newRef.set(promo);
  }

  // Delete a promotion
  static Future<void> deletePromotion(String id) async {
    // We need to find the node with this ID if it's a list, or just delete by key if it's a map.
    // The current seed saves as a list (0, 1, 2, 3).
    // But pushing uses random keys. Firebase handles mixing nicely usually, but best to stick to one.
    // Let's assume we might transition to Map-based storage with push() keys.

    // If it was seeded as a list, we might have issues deleting by "id" field unless we query.
    // Let's try to delete by query.
    final snapshot = await _dbRef
        .child('promotions')
        .orderByChild('id')
        .equalTo(id)
        .get();
    if (snapshot.exists) {
      for (final child in snapshot.children) {
        await child.ref.remove();
      }
    }
  }

  // Update a promotion
  static Future<void> updatePromotion(
    String id,
    Map<String, dynamic> data,
  ) async {
    final snapshot = await _dbRef
        .child('promotions')
        .orderByChild('id')
        .equalTo(id)
        .get();
    if (snapshot.exists) {
      for (final child in snapshot.children) {
        // Ensure ID stays the same
        data['id'] = id;
        await child.ref.update(data);
      }
    }
  }

  // Seed default promotions if not exists
  static Future<void> checkAndSeedPromotions() async {
    try {
      final snapshot = await _dbRef
          .child('promotions')
          .get()
          .timeout(const Duration(seconds: 10));
      if (snapshot.exists) return;

      debugPrint('Seeding default promotions...');
      // Use push() keys for consistency so we can delete them easily later
      final List<Map<String, dynamic>> defaultPromotions = PromotionsData
          .fallbackPromotions
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      for (var promo in defaultPromotions) {
        final ref = _dbRef.child('promotions').push();
        promo['id'] = ref.key;
        await ref.set(promo);
      }
    } catch (e) {
      debugPrint('Error checking/seeding promotions: $e');
    }
  }
}
