import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

class AddServiceScreen extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String? serviceId;
  final Map<String, dynamic>? initialData;

  const AddServiceScreen({
    super.key,
    required this.onSave,
    required this.onCancel,
    this.serviceId,
    this.initialData,
  });

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  bool _isSaving = false;
  Uint8List? _imageBytes;
  String? _existingImageUrl;
  String _selectedCategory = 'Body';

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {};
    _nameController.text = data['name'] ?? data['title'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _priceController.text = data['price']?.toString() ?? '';
    _durationController.text = data['duration'] ?? '';
    _existingImageUrl = data['imageUrl'];
    final imageBase64 = data['imageBase64'] as String?;
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        _imageBytes = base64Decode(imageBase64);
      } catch (_) {
        _imageBytes = null;
      }
    }

    final validCategories = ['Body', 'Facials', 'Beauty', 'General'];
    final initialCat = (data['category'] ?? '').toString().trim();

    if (initialCat.isNotEmpty && validCategories.contains(initialCat)) {
      _selectedCategory = initialCat;
    } else {
      // Derive from serviceId path if available (e.g., "Body/<key>")
      final idPath = (widget.serviceId ?? '').toString();
      if (idPath.contains('/')) {
        final derived = idPath.split('/').first;
        if (validCategories.contains(derived)) {
          _selectedCategory = derived;
        }
      }
    }
  }

  // _uploadImage is no longer needed as upload happens in _pickImage via helper
  Future<void> _pickLocalImage() async {
    try {
      final picker = ImagePicker();
      final XFile? img = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (img != null) {
        final bytes = await img.readAsBytes();
        if (mounted) {
          setState(() {
            _imageBytes = bytes;
            _existingImageUrl = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final priceStr = _priceController.text.trim();
    final duration = _durationController.text.trim();

    if (name.isEmpty ||
        description.isEmpty ||
        priceStr.isEmpty ||
        duration.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final price = double.tryParse(priceStr);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final imageUrl = _existingImageUrl;

      if (widget.serviceId != null) {
        // Edit existing service
        final Map<String, dynamic> newData = {
          'title': name,
          'name': name,
          'description': description,
          'price': price,
          'duration': duration,
          'time': duration,
          'imageUrl': imageUrl,
          if (_imageBytes != null) 'imageBase64': base64Encode(_imageBytes!),
          'updatedAt': ServerValue.timestamp,
          'category': _selectedCategory,
        };

        final rootPath =
            widget.initialData?['_rootPath'] as String? ?? 'service_catalog';

        // Construct full path: rootPath + / + serviceId (which is the relative path)
        await FirebaseDatabase.instance
            .ref(rootPath)
            .child(widget.serviceId!)
            .update(newData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service Updated Successfully')),
          );
          widget.onSave();
        }
      } else {
        // Add new service (RTDB) under selected category
        final newRef = FirebaseDatabase.instance
            .ref('service_catalog')
            .child(_selectedCategory)
            .push();
        await newRef.set({
          'title': name,
          'name': name,
          'description': description,
          'price': price,
          'duration': duration,
          'time': duration,
          'imageUrl': imageUrl,
          if (_imageBytes != null) 'imageBase64': base64Encode(_imageBytes!),
          'category': _selectedCategory,
          'createdAt': ServerValue.timestamp,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service added successfully!')),
          );
          widget.onSave(); // Navigate back
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving service: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

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
                    'Service Catalog',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D5343),
                    ),
                  ),
                  Text(
                    'Welcome back! Admin 1',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              Row(
                children: [
                  // Profile Dropdown (Reused from Dashboard)
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
                    'Admin1',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Save Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveService,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D5343), // Dark Brown
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.serviceId != null ? 'UPDATE' : 'SAVE',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),

          const SizedBox(height: 32),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form Section
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service Name
                        const Text(
                          'Service',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D5343),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFE5E0D0), // Light Beige
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D5343),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFE5E0D0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D5343),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E0D0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Body',
                                  child: Text('Body'),
                                ),
                                DropdownMenuItem(
                                  value: 'Facials',
                                  child: Text('Facials'),
                                ),
                                DropdownMenuItem(
                                  value: 'Beauty',
                                  child: Text('Beauty'),
                                ),
                                DropdownMenuItem(
                                  value: 'General',
                                  child: Text('General'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedCategory = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          'Time Duration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D5343),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _durationController,
                          decoration: InputDecoration(
                            hintText: 'e.g. 30 mins',
                            filled: true,
                            fillColor: const Color(0xFFE5E0D0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Price
                        const Text(
                          'Price',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D5343),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Text(
                                'RM',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 150,
                              child: TextField(
                                controller: _priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFE5E0D0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 48),

                // Upload Image Section
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      const SizedBox(height: 30), // Align with form top roughly
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E0D0),
                          borderRadius: BorderRadius.circular(24),
                          image: _imageBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(_imageBytes!),
                                  fit: BoxFit.cover,
                                )
                              : (_existingImageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_existingImageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                        ),
                        child: (_imageBytes == null && _existingImageUrl == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 64,
                                    color: Color(0xFF5D5343),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No image selected',
                                    style: TextStyle(
                                      color: Color(0xFF5D5343),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : null),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _pickLocalImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Pick Image (Local)'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveService,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D5343),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Save Service'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: widget.onCancel,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
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
