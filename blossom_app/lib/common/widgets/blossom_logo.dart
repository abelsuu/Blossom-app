import 'package:flutter/material.dart';

class BlossomLogo extends StatelessWidget {
  final double width;
  final double height;
  final bool withText;

  const BlossomLogo({
    super.key,
    this.width = 200,
    this.height = 200,
    this.withText = true,
  });

  @override
  Widget build(BuildContext context) {
    // Try to load asset, fallback to text/icon if error (or while developing)
    return Image.asset(
      'assets/images/blossom_logo.jpg',
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback placeholder if asset is missing
        return Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.spa, size: width * 0.3, color: Colors.black54),
            ],
          ),
        );
      },
    );
  }
}
