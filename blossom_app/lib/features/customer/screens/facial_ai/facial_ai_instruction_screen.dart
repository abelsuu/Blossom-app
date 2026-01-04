import 'package:flutter/material.dart';

class FacialAIInstructionScreen extends StatelessWidget {
  const FacialAIInstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Beige background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3142)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Instructions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3142),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
        child: Column(
          children: [
            Text(
              "How to take a photo",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Follow these guidelines for the best results",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 32),
            _buildInstructionCard(
              context,
              isCorrect: true,
              imageUrl:
                  'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=400', // Front face
              title: 'Correct way',
              description:
                  'Make sure the camera capture your\nface fully with a better lightning\nand without makeup.',
            ),
            const SizedBox(height: 24),
            _buildInstructionCard(
              context,
              isCorrect: false,
              imageUrl:
                  'https://images.unsplash.com/photo-1500917293891-ef795e70e1f6?q=80&w=400', // Side profile
              title: 'Wrong way',
              description:
                  'Avoid provide a half face photo as\nit could give wrong analysis.',
            ),
            const SizedBox(height: 24),
            _buildInstructionCard(
              context,
              isCorrect: false,
              imageUrl:
                  'https://images.unsplash.com/photo-1513279929416-4e0299063b33?q=80&w=400', // Poor lighting
              title: 'Poor lighting',
              description:
                  'Ensure bright, even lighting.\nAvoid dark rooms, shadows, or backlight.',
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'I Understand',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard(
    BuildContext context, {
    required bool isCorrect,
    required String imageUrl,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Image
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Status Icon (Check or X)
              Positioned(
                bottom: -20,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCorrect
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE57373),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isCorrect
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFE57373))
                                  .withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      isCorrect ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32), // Space for the icon
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isCorrect
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFE57373),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
