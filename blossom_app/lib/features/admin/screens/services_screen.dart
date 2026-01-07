import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'add_service_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  bool _isAddingService = false;
  String? _editingServiceId;
  Map<String, dynamic>? _editingServiceData;

  Future<List<Map<String, dynamic>>> _fetchAllServices() async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint(
      'Admin fetch: current user email=${user?.email}, uid=${user?.uid}',
    );

    Future<List<Map<String, dynamic>>> fetchFromPath(String refPath) async {
      final dbRef = FirebaseDatabase.instance.ref(refPath);
      debugPrint('Database Reference: $refPath');
      try {
        final snapshot = await dbRef.get();
        debugPrint('RTDB "$refPath" value exists: ${snapshot.exists}');
        if (!snapshot.exists) return [];

        final dynamic data = snapshot.value;
        debugPrint('Data type @"$refPath": ${data.runtimeType}');
        final List<Map<String, dynamic>> items = [];

        void extractServices(dynamic value, [String? parentId]) {
          if (value == null) return;
          if (value is Map) {
            final hasTitle =
                value.containsKey('title') || value.containsKey('name');
            final hasDesc =
                value.containsKey('description') || value.containsKey('desc');
            if (hasTitle && hasDesc) {
              final safeMap = Map<String, dynamic>.from(
                value.map((k, v) => MapEntry(k.toString(), v)),
              );
              String category = safeMap['category'] ?? '';
              if (category.isEmpty &&
                  parentId != null &&
                  parentId.contains('/')) {
                final parts = parentId.split('/');
                category = parts.first;
              }
              items.add({
                'id': parentId ?? 'unknown',
                'title': safeMap['title'] ?? safeMap['name'] ?? 'Untitled',
                'description': safeMap['description'] ?? safeMap['desc'] ?? '',
                'price': safeMap['price'] ?? safeMap['rmPrice'] ?? 0,
                'duration': safeMap['duration'] ?? safeMap['time'],
                'imageUrl': safeMap['imageUrl'] ?? safeMap['image'],
                'category': category,
                '_rootPath': refPath,
              });
            } else {
              value.forEach((k, v) {
                final newId = parentId != null ? '$parentId/$k' : k.toString();
                extractServices(v, newId);
              });
            }
          } else if (value is List) {
            for (int i = 0; i < value.length; i++) {
              final item = value[i];
              final newId = parentId != null ? '$parentId/$i' : i.toString();
              extractServices(item, newId);
            }
          }
        }

        extractServices(data);
        debugPrint('Fetched ${items.length} services from "$refPath"');
        return items;
      } catch (e) {
        debugPrint('Error fetching services from "$refPath": $e');
        return [];
      }
    }

    // Only fetch from service_catalog (the standard source)
    return await fetchFromPath('service_catalog');
  }

  @override
  Widget build(BuildContext context) {
    if (_isAddingService) {
      return AddServiceScreen(
        serviceId: _editingServiceId,
        initialData: _editingServiceData,
        onSave: () {
          setState(() {
            _isAddingService = false;
            _editingServiceId = null;
            _editingServiceData = null;
          });
        },
        onCancel: () {
          setState(() {
            _isAddingService = false;
            _editingServiceId = null;
            _editingServiceData = null;
          });
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Catalog',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D5343),
            ),
          ),
          const Text(
            'Welcome back Admin 1',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchAllServices(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5D5343)),
                  );
                }
                final services = snapshot.data ?? <Map<String, dynamic>>[];
                if (services.isEmpty) {
                  return Center(child: _buildAddServiceCard());
                }
                // Group by category
                final Map<String, List<Map<String, dynamic>>> byCategory = {};
                for (final s in services) {
                  final catRaw = (s['category'] ?? '').toString().trim();
                  // Derive category from id path if missing
                  String category = catRaw.isNotEmpty
                      ? catRaw
                      : (() {
                          final id = (s['id'] ?? '').toString();
                          if (id.contains('/')) {
                            return id.split('/').first;
                          }
                          return 'Uncategorized';
                        })();
                  byCategory.putIfAbsent(category, () => []).add(s);
                }

                // Preferred category ordering
                final List<String> preferredOrder = [
                  'Body',
                  'Facials',
                  'Beauty',
                  'General',
                  'Uncategorized',
                ];
                final categories = byCategory.keys.toList();
                categories.sort((a, b) {
                  int ia = preferredOrder.indexOf(a);
                  int ib = preferredOrder.indexOf(b);
                  if (ia == -1 && ib == -1) return a.compareTo(b);
                  if (ia == -1) return 1;
                  if (ib == -1) return -1;
                  return ia.compareTo(ib);
                });

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final category in categories) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5D5343),
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.8,
                              ),
                          itemCount: byCategory[category]!.length,
                          itemBuilder: (context, index) {
                            final service = byCategory[category]![index];
                            final docId = service['id'] as String? ?? '';
                            return _buildServiceCard(docId, service, Icons.spa);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildAddServiceCard(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteService(
    String docId,
    Map<String, dynamic> serviceData,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final rootPath =
            serviceData['_rootPath'] as String? ?? 'service_catalog';
        await FirebaseDatabase.instance.ref(rootPath).child(docId).remove();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service deleted successfully')),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting service: $e')));
        }
      }
    }
  }

  Widget _buildServiceCard(
    String docId,
    Map<String, dynamic> serviceData,
    IconData icon,
  ) {
    final title =
        serviceData['title'] ?? serviceData['name'] ?? 'Unknown Service';
    final description = serviceData['description'] ?? 'No description';
    // Price and other details are hidden on the card as requested
    final imageUrl = serviceData['imageUrl'] as String?;
    final imageBase64 = serviceData['imageBase64'] as String?;
    Uint8List? imageBytes;
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(imageBase64);
      } catch (_) {}
    }

    ImageProvider? bgImage;
    if (imageBytes != null) {
      bgImage = MemoryImage(imageBytes);
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      bgImage = NetworkImage(imageUrl);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _editingServiceId = docId;
          _editingServiceData = serviceData;
          _isAddingService = true;
        });
      },
      child: Stack(
        children: [
          Container(
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
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEE6D3),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      image: bgImage != null
                          ? DecorationImage(image: bgImage, fit: BoxFit.cover)
                          : null,
                    ),
                    child: bgImage == null
                        ? Center(
                            child: Icon(
                              icon,
                              size: 48,
                              color: const Color(0xFF5D5343),
                            ),
                          )
                        : null,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF5D5343),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 3, // Show a bit more preview
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                    onPressed: () {
                      setState(() {
                        _editingServiceId = docId;
                        _editingServiceData = serviceData;
                        _isAddingService = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _deleteService(docId, serviceData),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddServiceCard() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isAddingService = true;
          _editingServiceId = null;
          _editingServiceData = null;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFDFCF2), // Light background for add card
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF5D5343),
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Icon(Icons.add, size: 48, color: Color(0xFF5D5343)),
        ),
      ),
    );
  }
}
