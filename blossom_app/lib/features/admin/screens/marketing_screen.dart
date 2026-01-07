import 'package:blossom_app/features/customer/services/promotions_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _treatmentsController = TextEditingController();
  DateTime? _validUntil;
  String? _uploadedImageUrl;

  int _selectedThemeIndex = 0;
  int _selectedImageIndex = 0;
  String? _editingId;

  final List<Map<String, dynamic>> _themes = [
    {
      'name': 'Olive Nature',
      'color': 0xFF556B2F,
      'textColor': 0xFFFFFFFF,
      'pillColor': 0xCCFFFFFF,
    },
    {
      'name': 'Sky Blue',
      'color': 0xFF81D4FA,
      'textColor': 0xFF424242,
      'pillColor': 0x99FFFFFF,
    },
    {
      'name': 'Rose Pink',
      'color': 0xFFF48FB1,
      'textColor': 0xFF424242,
      'pillColor': 0x99FFFFFF,
    },
    {
      'name': 'Fresh Green',
      'color': 0xFF9CCC65,
      'textColor': 0xFF424242,
      'pillColor': 0x99FFFFFF,
    },
    {
      'name': 'Elegant Brown',
      'color': 0xFF5D4037,
      'textColor': 0xFFFFFFFF,
      'pillColor': 0xCCFFFFFF,
    },
  ];

  final List<String> _images = [
    'https://images.unsplash.com/photo-1544717305-2782549b5136?q=80&w=200',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=200',
    'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?q=80&w=200',
    'https://images.unsplash.com/photo-1515377905703-c4788e51af15?q=80&w=200',
    'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1596755389378-c31d21fd1273?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _treatmentsController.dispose();
    super.dispose();
  }

  void _editPromo(Map<String, dynamic> promo) {
    setState(() {
      _editingId = promo['id'];
      _titleController.text = promo['title'] ?? '';
      _subtitleController.text = promo['subtitle'] ?? '';
      _descriptionController.text = promo['description'] ?? '';
      _treatmentsController.text = promo['applicableTreatments'] ?? '';

      if (promo['validUntil'] != null) {
        _validUntil = DateTime.tryParse(promo['validUntil']);
      } else {
        _validUntil = null;
      }

      // Find matching theme or default to 0
      final promoColor = promo['color'];
      final themeIndex = _themes.indexWhere((t) => t['color'] == promoColor);
      _selectedThemeIndex = themeIndex != -1 ? themeIndex : 0;

      // Find matching image or set as uploaded
      final promoImage = promo['imageUrl'];
      final imageIndex = _images.indexOf(promoImage);
      if (imageIndex != -1) {
        _selectedImageIndex = imageIndex;
        _uploadedImageUrl = null;
      } else {
        _selectedImageIndex = -1; // Custom image
        _uploadedImageUrl = promoImage;
      }
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _titleController.clear();
      _subtitleController.clear();
      _descriptionController.clear();
      _treatmentsController.clear();
      _validUntil = null;
      _uploadedImageUrl = null;
      _selectedThemeIndex = 0;
      _selectedImageIndex = 0;
    });
  }

  void _publishOffer() {
    if (_titleController.text.isEmpty || _subtitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and subtitle')),
      );
      return;
    }

    String imageUrl;
    if (_uploadedImageUrl != null) {
      imageUrl = _uploadedImageUrl!;
    } else if (_selectedImageIndex >= 0 &&
        _selectedImageIndex < _images.length) {
      imageUrl = _images[_selectedImageIndex];
    } else {
      imageUrl = _images[0]; // Fallback
    }

    final theme = _themes[_selectedThemeIndex];
    final promo = {
      'title': _titleController.text,
      'subtitle': _subtitleController.text,
      'description': _descriptionController.text,
      'applicableTreatments': _treatmentsController.text,
      'validUntil': _validUntil?.toIso8601String(),
      'imageUrl': imageUrl,
      'color': theme['color'],
      'textColor': theme['textColor'],
      'pillColor': theme['pillColor'],
      'createdAt': DateTime.now().toIso8601String(),
    };

    if (_editingId != null) {
      PromotionsService.updatePromotion(_editingId!, promo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Special Offer Updated!'),
          backgroundColor: Color(0xFF556B2F),
        ),
      );
      _cancelEdit();
    } else {
      PromotionsService.addPromotion(promo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Special Offer Published!'),
          backgroundColor: Color(0xFF556B2F),
        ),
      );
      _titleController.clear();
      _subtitleController.clear();
      _descriptionController.clear();
      _treatmentsController.clear();
      _validUntil = null;
      _uploadedImageUrl = null;
    }
  }

  void _deletePromo(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offer?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              PromotionsService.deletePromotion(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
                    'Marketing & Promotions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D5343),
                    ),
                  ),
                  Text(
                    'Manage your special offers and campaigns',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              Row(
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
                    'Admin1',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side - Active Promotions List
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Campaigns',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D5343),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: PromotionsService.getPromotionsStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final promotions = snapshot.data ?? [];
                            if (promotions.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.campaign_outlined,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No active promotions yet.\nCreate one on the right!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.separated(
                              itemCount: promotions.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final promo = promotions[index];
                                return _buildPromoListItem(promo);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Right Side - Create Offer Form
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xFF5D5343),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _editingId != null
                                    ? 'Edit Offer'
                                    : 'Create Creative Offer',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5D5343),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Live Preview
                          const Text(
                            'Live Preview',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(child: _buildLivePreviewCard()),
                          const SizedBox(height: 24),

                          // Form Fields
                          _buildCreativeTextField(
                            controller: _titleController,
                            label: 'Catchy Title',
                            icon: Icons.title,
                            hint: 'e.g. Holiday Specials',
                          ),
                          const SizedBox(height: 16),
                          _buildCreativeTextField(
                            controller: _subtitleController,
                            label: 'Subtitle / Tagline',
                            icon: Icons.subtitles,
                            hint: 'e.g. Free gift included',
                          ),
                          const SizedBox(height: 16),

                          // Valid Until Date Picker
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _validUntil ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setState(() {
                                  _validUntil = date;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFF8E1,
                                ).withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFFCFA6A6),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _validUntil != null
                                        ? 'Valid Until: ${DateFormat('yyyy-MM-dd').format(_validUntil!)}'
                                        : 'Select Expiry Date',
                                    style: TextStyle(
                                      color: _validUntil != null
                                          ? Colors.black87
                                          : Colors.grey.shade400,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildCreativeTextField(
                            controller: _descriptionController,
                            label: 'Detailed Information',
                            icon: Icons.info_outline,
                            hint: 'Terms, conditions, description...',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),

                          _buildCreativeTextField(
                            controller: _treatmentsController,
                            label: 'Applicable Treatment (Exact Name)',
                            icon: Icons.spa,
                            hint: 'e.g. Anti-Aging Facial',
                          ),
                          const SizedBox(height: 24),

                          // Theme Selector
                          const Text(
                            'Select Theme',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5D5343),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 50,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _themes.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final theme = _themes[index];
                                final isSelected = _selectedThemeIndex == index;
                                return GestureDetector(
                                  onTap: () => setState(
                                    () => _selectedThemeIndex = index,
                                  ),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Color(theme['color']),
                                      shape: BoxShape.circle,
                                      border: isSelected
                                          ? Border.all(
                                              color: const Color(0xFF5D5343),
                                              width: 3,
                                            )
                                          : null,
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color: Color(
                                              theme['color'],
                                            ).withValues(alpha: 0.5),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                      ],
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Image Selector
                          const Text(
                            'Select Visual',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5D5343),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Custom upload removed as per request
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _images.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final isSelected = _selectedImageIndex == index;
                                return GestureDetector(
                                  onTap: () => setState(
                                    () => _selectedImageIndex = index,
                                  ),
                                  child: Container(
                                    width: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: isSelected
                                          ? Border.all(
                                              color: const Color(0xFF5D5343),
                                              width: 3,
                                            )
                                          : null,
                                      image: DecorationImage(
                                        image: NetworkImage(_images[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.3,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          Row(
                            children: [
                              if (_editingId != null) ...[
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _cancelEdit,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      side: const BorderSide(
                                        color: Colors.grey,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _publishOffer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5D5343),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    _editingId != null
                                        ? 'Update Offer'
                                        : 'Publish Offer',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoListItem(Map<String, dynamic> promo) {
    return Container(
      width: double.infinity,
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 100,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(promo['imageUrl'] ?? ''),
                fit: BoxFit.cover,
              ),
              color: Colors.grey.shade200,
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  promo['title'] ?? 'No Title',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D5343),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Color(
                      promo['color'] ?? 0xFF556B2F,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    promo['subtitle'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(promo['color'] ?? 0xFF556B2F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Row(
            children: [
              IconButton(
                onPressed: () => _editPromo(promo),
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF5D5343)),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: () => _deletePromo(promo['id'] ?? ''),
                icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard() {
    final theme = _themes[_selectedThemeIndex];
    String imageUrl;
    if (_uploadedImageUrl != null) {
      imageUrl = _uploadedImageUrl!;
    } else if (_selectedImageIndex >= 0 &&
        _selectedImageIndex < _images.length) {
      imageUrl = _images[_selectedImageIndex];
    } else {
      imageUrl = _images[0];
    }

    return Container(
      width: 280,
      height: 160,
      decoration: BoxDecoration(
        color: Color(theme['color']),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(theme['color']).withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _titleController.text.isEmpty
                      ? 'Your Title Here'
                      : _titleController.text,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(theme['textColor']),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Color(theme['pillColor']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _subtitleController.text.isEmpty
                        ? 'Your offer details'
                        : _subtitleController.text,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(theme['textColor']),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -15,
            bottom: -15,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreativeTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}), // Trigger rebuild for preview
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade300),
            prefixIcon: maxLines == 1
                ? Icon(icon, color: const Color(0xFFCFA6A6), size: 20)
                : Container(
                    padding: const EdgeInsets.only(
                      bottom: 48,
                    ), // Align icon top
                    child: Icon(icon, color: const Color(0xFFCFA6A6), size: 20),
                  ),
            filled: true,
            fillColor: const Color(0xFFFFF8E1).withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCFA6A6), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
          ),
        ),
      ],
    );
  }
}
