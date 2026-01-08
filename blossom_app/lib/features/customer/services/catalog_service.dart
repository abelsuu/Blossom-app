import 'package:blossom_app/core/constants/catalog_data.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class CatalogService {
  static final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Get fallback data synchronously for initialData
  static List<Map<String, dynamic>> getFallbackData(String category) {
    final list = CatalogData.fallbackData[category] ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static List<Map<String, dynamic>> getFallbackAllServices() {
    final List<Map<String, dynamic>> fbAll = [];
    CatalogData.fallbackData.forEach((category, services) {
      fbAll.addAll(services.map((e) => Map<String, dynamic>.from(e)));
    });
    return fbAll;
  }

  // Check if data exists, if not, seed it
  static Future<void> checkAndSeedData() async {
    try {
      final snapshot = await _dbRef
          .child('service_catalog')
          .get()
          .timeout(const Duration(seconds: 10));
      if (!snapshot.exists) {
        debugPrint('No catalog data found. Seeding default data...');
        await seedCatalogData();
      } else {
        debugPrint('Catalog data already exists. Skipping seed.');
      }
    } catch (e) {
      debugPrint('Error checking/seeding catalog data: $e');
    }
  }

  // Seed the database with initial catalog data
  static Future<void> seedCatalogData() async {
    try {
      await _dbRef.child('service_catalog').set(CatalogData.fallbackData);
      debugPrint('Catalog data seeded successfully');
    } catch (e) {
      debugPrint('Error seeding catalog data: $e');
      rethrow;
    }
  }

  // Fetch services for a specific category
  static Stream<List<Map<String, dynamic>>> getServicesStream(String category) {
    final query = _dbRef.child('service_catalog/$category');
    if (!kIsWeb) {
      query.keepSynced(true);
    }
    return query.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      // Data is likely a List because we seeded it as a List
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      // Fallback if it somehow becomes a Map
      else if (data is Map) {
        return data.values
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      return [];
    });
  }

  static Stream<List<Map<String, dynamic>>> getServicesStreamWithFallback(
    String category,
  ) {
    final query = _dbRef.child('service_catalog/$category');
    if (!kIsWeb) {
      query.keepSynced(true);
    }
    return query.onValue.map((event) {
      final data = event.snapshot.value;
      List<Map<String, dynamic>> out = [];
      if (data is List) {
        out = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else if (data is Map) {
        out = data.values
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      // Return actual data (even if empty) to show Realtime Database state
      // Initial fallback is handled by StreamBuilder's initialData
      return out;
    });
  }

  // Fetch ALL services (flattened list)
  static Stream<List<Map<String, dynamic>>> getAllServicesStream() {
    final query = _dbRef.child('service_catalog');
    if (!kIsWeb) {
      query.keepSynced(true);
    }
    return query.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final List<Map<String, dynamic>> allServices = [];

      if (data is Map) {
        data.forEach((category, services) {
          if (services is List) {
            allServices.addAll(
              services.map((e) => Map<String, dynamic>.from(e as Map)),
            );
          } else if (services is Map) {
            allServices.addAll(
              services.values.map((e) => Map<String, dynamic>.from(e as Map)),
            );
          }
        });
      }

      return allServices;
    });
  }

  static Stream<List<Map<String, dynamic>>> getAllServicesStreamWithFallback() {
    final query = _dbRef.child('service_catalog');
    if (!kIsWeb) {
      query.keepSynced(true);
    }
    return query.onValue.map((event) {
      final data = event.snapshot.value;
      final List<Map<String, dynamic>> allServices = [];

      try {
        if (data is Map) {
          data.forEach((category, services) {
            if (services is List) {
              allServices.addAll(
                services.map((e) => Map<String, dynamic>.from(e as Map)),
              );
            } else if (services is Map) {
              allServices.addAll(
                services.values.map((e) => Map<String, dynamic>.from(e as Map)),
              );
            }
          });
        } else if (data is List) {
          // Handle case where root might be a List (unexpected but possible)
          for (var item in data) {
            if (item is Map) {
              // If the list items are categories? Or flattened services?
              // Assuming standard structure, this branch is unlikely unless schema changed.
              // But if it's a list of services directly:
              if (item.containsKey('title')) {
                allServices.add(Map<String, dynamic>.from(item));
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error parsing service catalog: $e');
      }

      // Return fallback data if stream result is empty
      // This ensures "No services available" is never shown if we have local fallback
      if (allServices.isEmpty) {
        debugPrint('Stream returned empty. Using fallback data.');
        return getFallbackAllServices();
      }

      return allServices;
    });
  }
}
