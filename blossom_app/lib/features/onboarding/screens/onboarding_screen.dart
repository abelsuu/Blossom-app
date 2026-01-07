import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blossom_app/features/auth/screens/login_screen.dart';
import 'package:blossom_app/features/customer/screens/signup/signup_basic_info_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {"text": "SPA only for\nWomen", "image": "assets/images/spa-for-women.png"},
    {
      "text": "Providing you with\nAI Skin Analysis\nFeature",
      "image": "assets/images/ai-skin-analysis.png",
    },
    {
      "text": "Friendly Staffs\nto Serve you",
      "image": "assets/images/pic-staff.jpg",
    },
    {"text": "Comfortable\nSpace", "image": "assets/images/ruang.jpg"},
    {"text": "Affordable\nServices", "image": "assets/images/service.jpg"},
  ];

  @override
  void initState() {
    super.initState();
    // TODO: Uncomment this to fetch from Firebase. Currently disabled to use local hardcoded data.
    // _fetchOnboardingConfig();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingData.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return OnboardingPage(
                text: _onboardingData[index]["text"]!,
                imageUrl: _onboardingData[index]["image"]!,
              );
            },
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Page Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardingData.length,
                    (index) => buildDot(index), // Shift index to match pages
                  ),
                ),
                const SizedBox(height: 30),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('seenOnboarding', true);

                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('seenOnboarding', true);

                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SignUpBasicInfoScreen(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Colors.white
            : Colors.white.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String text;
  final String imageUrl;

  const OnboardingPage({super.key, required this.text, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final fallbackUrl = _fallbackUrlForText(text);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        _buildImage(fallbackUrl),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),

        Positioned(
          bottom: 160,
          left: 20,
          right: 20,
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String fallbackUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback for asset failure
          return _buildFallbackImage(fallbackUrl);
        },
      );
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFFFFF8E1),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                color: const Color(0xFFCFA6A6),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage(fallbackUrl);
        },
      );
    }
  }

  Widget _buildFallbackImage(String fallbackUrl) {
    // Specific check for AI Skin Analysis to force local asset fallback
    if (text.toLowerCase().contains('ai skin')) {
      return Image.asset(
        'assets/images/ai-skin-analysis.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    }

    if (fallbackUrl.startsWith('assets/')) {
      return Image.asset(
        fallbackUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    }

    // Generic Network Fallback
    return Image.network(
      fallbackUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorPlaceholder();
      },
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: const Color(0xFFFFF8E1),
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: Color(0xFFCFA6A6),
          size: 48,
        ),
      ),
    );
  }

  String _fallbackUrlForText(String t) {
    final lower = t.toLowerCase();
    if (lower.contains('ai skin')) {
      return 'assets/images/ai-skin-analysis.png';
    }
    if (lower.contains('friendly staffs')) {
      return 'assets/images/pic-staff.jpg';
    }
    if (lower.contains('comfortable')) {
      return 'assets/images/ruang.jpg';
    }
    if (lower.contains('affordable')) {
      return 'assets/images/service.jpg';
    }
    return 'assets/images/spa-for-women.png';
  }
}
