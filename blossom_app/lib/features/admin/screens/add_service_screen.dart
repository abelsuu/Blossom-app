import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _isPickingImage = false;
  XFile? _pickedFile;
  Uint8List? _imageBytes;
  String? _existingImageUrl;
  String _selectedCategory = 'Body';
  String _manualImageUrl = '';
  bool _useManualUrl = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {};
    _nameController.text = data['name'] ?? data['title'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _priceController.text = data['price']?.toString() ?? '';
    _durationController.text = data['duration'] ?? '';
    _existingImageUrl = data['imageUrl'];
    final initialCat = (data['category'] ?? '').toString().trim();
    if (initialCat.isNotEmpty) {
      _selectedCategory = initialCat;
    } else {
      // Derive from serviceId path if available (e.g., "Body/<key>")
      final idPath = (widget.serviceId ?? '').toString();
      if (idPath.contains('/')) {
        _selectedCategory = idPath.split('/').first;
      }
    }
  }

  Future<void> _pickImage() async {
    // Prevent multiple clicks
    if (_isPickingImage) return;

    final ImagePicker picker = ImagePicker();
    try {
      // Don't set _isPickingImage to true here, as pickImage is a UI blocking operation on some platforms
      // and we want to avoid UI jumps. We only need the loader when we are processing the result.

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        // Re-enabled compression for faster uploads
        maxWidth: 500,
        imageQuality: 60,
      );

      if (image != null) {
        setState(() {
          _isPickingImage =
              true; // Show loader only when we actually have an image to process
        });

        final bytes = await image.readAsBytes();

        if (mounted) {
          setState(() {
            _pickedFile = image;
            _imageBytes = bytes;
            _isPickingImage = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<String?> _uploadImage() async {
    // If using manual URL, return it directly
    if (_useManualUrl) {
      return _manualImageUrl.isNotEmpty ? _manualImageUrl : _existingImageUrl;
    }

    // Otherwise, try to upload file (but this will fail on free plan)
    if (_pickedFile == null || _imageBytes == null) return _existingImageUrl;

    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please sign in again.');
      }

      final storageRef = FirebaseStorage.instance.ref().child(
        'service_images/${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.name}',
      );

      // Use putData for cross-platform compatibility (Web & Mobile/Desktop)
      // Set content type explicitly to speed up processing
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      // Create upload task
      final uploadTask = storageRef.putData(_imageBytes!, metadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        debugPrint('Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      });

      // Wait for completion with timeout
      await uploadTask.timeout(
        const Duration(seconds: 60), // Increased timeout
        onTimeout: () {
          throw Exception(
            'Upload timed out. Please check your internet connection and try again.',
          );
        },
      );

      final downloadUrl = await storageRef.getDownloadURL();
      debugPrint('Upload successful: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      throw Exception('Error uploading image: $e');
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
      final imageUrl = await _uploadImage();

      if (widget.serviceId != null) {
        // Edit existing service
        final Map<String, dynamic> newData = {
          'title': name,
          'name': name,
          'description': description,
          'price': price,
          'duration': duration,
          'time': duration,
          'image': imageUrl, // Set both image and imageUrl for compatibility
          'imageUrl': imageUrl,
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
          'image': imageUrl, // Set both image and imageUrl for compatibility
          'imageUrl': imageUrl,
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
              onPressed: (_isSaving || _isPickingImage) ? null : _saveService,
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

                      // Toggle between file upload and manual URL
                      Row(
                        children: [
                          const Text(
                            'Upload File',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5D5343),
                            ),
                          ),
                          Switch(
                            value: _useManualUrl,
                            onChanged: (value) {
                              setState(() {
                                _useManualUrl = value;
                                if (value) {
                                  _pickedFile = null;
                                  _imageBytes = null;
                                }
                              });
                            },
                            activeColor: const Color(0xFF5D5343),
                          ),
                          const Text(
                            'Manual URL',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5D5343),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Manual URL input field
                      if (_useManualUrl) ...[
                        TextField(
                          onChanged: (value) {
                            _manualImageUrl = value;
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter image URL...',
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
                        const SizedBox(height: 16),
                      ],

                      // Image preview/upload area
                      GestureDetector(
                        onTap: _useManualUrl ? null : _pickImage,
                        child: Container(
                          height: 200,
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
                                          image: NetworkImage(
                                            _existingImageUrl!,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null),
                          ),
                          child: _isPickingImage
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Color(0xFF5D5343),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Processing...',
                                        style: TextStyle(
                                          color: Color(0xFF5D5343),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : (_imageBytes == null &&
                                        _existingImageUrl == null &&
                                        !_useManualUrl
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 48,
                                            color: Color(0xFF5D5343),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Click to upload image',
                                            style: TextStyle(
                                              color: Color(0xFF5D5343),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : _useManualUrl &&
                                            _manualImageUrl.isEmpty &&
                                            _existingImageUrl == null
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Icon(
                                                Icons.link,
                                                size: 48,
                                                color: Color(0xFF5D5343),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Enter URL above',
                                                style: TextStyle(
                                                  color: Color(0xFF5D5343),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          )
                                        : null),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Warning text for manual upload
                      if (!_useManualUrl) ...[
                        const Text(
                          '⚠️ Upload disabled on free plan',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                      ],

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
