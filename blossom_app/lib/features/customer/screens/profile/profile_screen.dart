import 'package:flutter/material.dart';
import 'package:blossom_app/features/customer/screens/profile/settings_screen.dart';
import 'package:blossom_app/features/customer/screens/ai_skin_analysis/ai_skin_analysis_screen.dart'
    show AiSkinAnalysisScreen;
import 'package:blossom_app/features/customer/screens/profile/profile_questionnaire_screen.dart';
import 'package:blossom_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:blossom_app/features/customer/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'My Profile',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: UserService.getUserProfileStream(user.uid),
        builder: (context, snapshot) {
          // Default data if loading or empty
          final data = snapshot.data ?? {};
          final firstName =
              data['firstName'] ??
              user.displayName?.split(' ').first ??
              'Guest';
          final age = data['age']; // Can be null
          final skinType = data['skinType'] ?? 'Unknown';
          final sensitivity = data['sensitivity'] ?? 'Unknown';
          final elasticity = data['elasticity'] ?? 'Unknown';
          final acneProne = data['acneProne'] ?? 'Unknown';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Column(
              children: [
                // Profile Header
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.spa,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      firstName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      age != null ? '$age years old' : 'Age not set',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Skin Stats
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSkinStatItem(
                        context,
                        'Skin Type',
                        skinType,
                        Icons.water_drop,
                        const Color(0xFFFFCCBC),
                      ),
                      _buildSkinStatItem(
                        context,
                        'Sensitivity',
                        sensitivity,
                        Icons.grain,
                        const Color(0xFFF8BBD0),
                      ),
                      _buildSkinStatItem(
                        context,
                        'Elasticity',
                        elasticity,
                        Icons.wb_sunny,
                        const Color(0xFFFFF59D),
                      ),
                      _buildSkinStatItem(
                        context,
                        'Acne Prone',
                        acneProne,
                        Icons.error_outline,
                        const Color(0xFFFFAB91),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButton(
                  context,
                  'Advanced Skin Analysis',
                  'Identify your skin profile just with selfie!',
                  Icons.face_retouching_natural,
                  const Color(0xFFEBE6C8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AiSkinAnalysisScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context,
                  'Tell us more about your situation',
                  'Answer questions about your habits and preferences',
                  Icons.checklist,
                  const Color(0xFFFFF59D),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfileQuestionnaireScreen(currentData: data),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // List Options
                _buildListOption(context, 'Lifestyle Choices'),
                _buildListOption(context, 'Forbidden Ingredients'),
                _buildListOption(context, 'Favorite Ingredients'),
                _buildListOption(
                  context,
                  'Age',
                  trailingText: age?.toString() ?? '--',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfileQuestionnaireScreen(currentData: data),
                      ),
                    );
                  },
                ),
                _buildListOption(context, 'Melanin Level'),
                const SizedBox(height: 30),

                // Log Out Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const OnboardingScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkinStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color bgColor,
  ) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black87, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListOption(
    BuildContext context,
    String title, {
    String? trailingText,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getIconColorForOption(title).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconDataForOption(title),
                size: 18,
                color: _getIconColorForOption(title),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconDataForOption(String title) {
    switch (title) {
      case 'Lifestyle Choices':
        return Icons.public;
      case 'Forbidden Ingredients':
        return Icons.block;
      case 'Favorite Ingredients':
        return Icons.favorite;
      case 'Age':
        return Icons.cake;
      case 'Melanin Level':
        return Icons.cookie;
      default:
        return Icons.circle;
    }
  }

  Color _getIconColorForOption(String title) {
    switch (title) {
      case 'Lifestyle Choices':
        return Colors.green;
      case 'Forbidden Ingredients':
        return Colors.red;
      case 'Favorite Ingredients':
        return Colors.pink;
      case 'Age':
        return Colors.orange;
      case 'Melanin Level':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
