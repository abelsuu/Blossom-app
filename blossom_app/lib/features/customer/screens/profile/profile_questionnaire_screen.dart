import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blossom_app/features/customer/services/user_service.dart';

class ProfileQuestionnaireScreen extends StatefulWidget {
  final Map<String, dynamic> currentData;

  const ProfileQuestionnaireScreen({super.key, required this.currentData});

  @override
  State<ProfileQuestionnaireScreen> createState() =>
      _ProfileQuestionnaireScreenState();
}

class _ProfileQuestionnaireScreenState
    extends State<ProfileQuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ageController;

  String? _skinType;
  String? _sensitivity;
  String? _elasticity;
  String? _acneProne;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(
      text: widget.currentData['age']?.toString() ?? '',
    );
    _skinType = widget.currentData['skinType'] == 'Unknown'
        ? null
        : widget.currentData['skinType'];
    _sensitivity = widget.currentData['sensitivity'] == 'Unknown'
        ? null
        : widget.currentData['sensitivity'];
    _elasticity = widget.currentData['elasticity'] == 'Unknown'
        ? null
        : widget.currentData['elasticity'];
    _acneProne = widget.currentData['acneProne'] == 'Unknown'
        ? null
        : widget.currentData['acneProne'];
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await UserService.updateUserProfile(user.uid, {
          'age': int.tryParse(_ageController.text),
          'skinType': _skinType ?? 'Unknown',
          'sensitivity': _sensitivity ?? 'Unknown',
          'elasticity': _elasticity ?? 'Unknown',
          'acneProne': _acneProne ?? 'Unknown',
        });
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Skin Profile',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about your skin',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Help us personalize your experience by answering a few questions.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),

              // Age Input
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Age',
                  hintText: 'Enter your age',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Skin Type Dropdown
              _buildDropdown(
                context,
                label: 'Skin Type',
                value: _skinType,
                items: ['Oily', 'Dry', 'Combination', 'Normal'],
                icon: Icons.water_drop_outlined,
                onChanged: (val) => setState(() => _skinType = val),
              ),

              // Sensitivity Dropdown
              _buildDropdown(
                context,
                label: 'Sensitivity',
                value: _sensitivity,
                items: ['Sensitive', 'Resilient'],
                icon: Icons.grain,
                onChanged: (val) => setState(() => _sensitivity = val),
              ),

              // Elasticity Dropdown
              _buildDropdown(
                context,
                label: 'Elasticity',
                value: _elasticity,
                items: ['Elastic', 'Firm', 'Sagging'],
                icon: Icons.wb_sunny_outlined,
                onChanged: (val) => setState(() => _elasticity = val),
              ),

              // Acne Prone Dropdown
              _buildDropdown(
                context,
                label: 'Acne Prone',
                value: _acneProne,
                items: ['Never', 'Rarely', 'Seasonal', 'Frequent'],
                icon: Icons.error_outline,
                onChanged: (val) => setState(() => _acneProne = val),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: theme.colorScheme.primary.withValues(
                      alpha: 0.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    // Ensure value is in items, otherwise null
    final validValue = items.contains(value) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: DropdownButtonFormField<String>(
        initialValue: validValue,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        icon: const Icon(Icons.keyboard_arrow_down),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
