import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:blossom_app/features/customer/services/user_service.dart';
import 'package:blossom_app/features/customer/screens/ai_skin_analysis/services/skin_analysis_service.dart';
import 'package:blossom_app/features/customer/screens/ai_skin_analysis/analysis_error_screen.dart';
import 'package:blossom_app/features/customer/screens/facial_ai/facial_ai_instruction_screen.dart';
import 'skin_analysis_result_screen.dart';
import 'skin_analysis_history_screen.dart';

class AiSkinAnalysisScreen extends StatefulWidget {
  final XFile? initialImage;
  final bool showBackButton;
  const AiSkinAnalysisScreen({
    super.key,
    this.initialImage,
    this.showBackButton = true,
  });

  @override
  State<AiSkinAnalysisScreen> createState() => _AiSkinAnalysisScreenState();
}

class _AiSkinAnalysisScreenState extends State<AiSkinAnalysisScreen> {
  bool _isAnalyzing = false;
  XFile? _selectedImage;

  final SkinAnalysisService _skinAnalysisService = SkinAnalysisService();
  final ImagePicker _picker = ImagePicker();
  String _loadingStatus = 'Analyzing...';

  @override
  void initState() {
    super.initState();
    if (widget.initialImage != null) {
      _selectedImage = widget.initialImage;
    }
  }

  Future<void> _resetLimitForTesting() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await UserService.resetSkinAnalysisLimit(user.uid);
      if (mounted) setState(() {});
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      _showStatus("Requesting permissions...");

      // 1. Request Permission explicitly (Mobile only)
      // On Web, the browser handles permissions automatically when pickImage is called.
      if (!kIsWeb && source == ImageSource.camera) {
        var status = await Permission.camera.status;
        if (!status.isGranted) {
          status = await Permission.camera.request();
          if (!status.isGranted) {
            _showError('Camera permission denied');
            return;
          }
        }
      }

      _showStatus(
        "Opening ${source == ImageSource.camera ? 'Camera' : 'Gallery'}...",
      );

      // 2. Pick Image
      final XFile? photo = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo != null) {
        _showStatus("Image captured! Processing...");
        setState(() {
          _selectedImage = photo;
        });
      } else {
        _showStatus("No image selected.");
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  void _showStatus(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _startAnalysis() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _loadingStatus = "Checking usage limits...";
    });

    try {
      // Check Limit
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final canAnalyze = await UserService.canAnalyzeSkin(user.uid);
        if (!canAnalyze) {
          if (mounted) {
            setState(() {
              _isAnalyzing = false;
            });
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Limit Reached'),
                content: const Text(
                  'You have used your 3 free skin analyses for this month. Please try again next month.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }

      setState(() {
        _loadingStatus = "Analyzing image with AI...";
      });

      // Call our service to analyze the image
      final results = await _skinAnalysisService.analyzeSkin(_selectedImage!);

      // Check for quality error
      if (results.containsKey('error') && results['error'] == 'poor_quality') {
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnalysisErrorScreen(
                onBack: () {
                  Navigator.pop(context); // Close error screen
                  // Optionally reset state or let user try again
                },
              ),
            ),
          );
        }
        return; // Stop processing
      }

      setState(() {
        _loadingStatus = "Saving results...";
      });

      // Increment Usage on Success
      if (user != null) {
        await UserService.incrementSkinAnalysisUsage(user.uid);
      }

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });

        final user = FirebaseAuth.instance.currentUser;
        final userName = user?.displayName ?? 'Guest';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SkinAnalysisResultScreen(result: results, userName: userName),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Skin Analysis'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: (_selectedImage != null && !_isAnalyzing)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                  });
                },
              )
            : (widget.showBackButton
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SkinAnalysisHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _isAnalyzing
            ? _buildAnalyzing()
            : _selectedImage != null
            ? _buildImagePreview()
            : _buildIntro(),
      ),
    );
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.face_retouching_natural,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Discover Your Skin Profile',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3142),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Take a clear selfie in natural light. Our AI will analyze your skin type, hydration, and concerns to recommend the best care.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FutureBuilder<int>(
            future: FirebaseAuth.instance.currentUser != null
                ? UserService.getRemainingSkinAnalysisCount(
                    FirebaseAuth.instance.currentUser!.uid,
                  )
                : Future.value(0),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final remaining = snapshot.data!;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: remaining > 0
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$remaining free analysis remaining this month',
                  style: TextStyle(
                    color: remaining > 0 ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FacialAIInstructionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFEBE6C8),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Instructions'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Selfie'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  backgroundColor: const Color(0xFFEBE6C8),
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Upload Photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  backgroundColor: const Color(0xFFEBE6C8),
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FutureBuilder<Uint8List>(
            future: _selectedImage!.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 400,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Container(
                  height: 400,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading image',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                height: 400,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: DecorationImage(
                    image: MemoryImage(snapshot.data!),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  label: const Text('Retake'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                  label: const Text('Upload'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startAnalysis,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Analyze Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shadowColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzing() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _loadingStatus,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3142),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Please wait while we process your image...',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
