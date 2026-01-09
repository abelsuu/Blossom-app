// A reusable layout widget for the different screens in the sign-up flow.
// This ensures a consistent look and feel (e.g., app bar, titles).

import 'package:flutter/material.dart';

// Shared styles and layout for SignUp Screens
class SignUpLayout extends StatelessWidget {
  // The main content to be displayed in the layout.
  final Widget child;
  // An optional callback for the back button.
  final VoidCallback? onBack;
  // The primary title of the screen.
  final String title;
  // An optional subtitle displayed below the title.
  final String? subtitle;

  const SignUpLayout({
    super.key,
    required this.child,
    this.onBack,
    this.title = 'SignUp',
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // Display a back button if the onBack callback is provided.
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: onBack,
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Display the title.
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              // Display the subtitle if it exists.
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
              const SizedBox(height: 30),
              // The main content of the screen is inserted here.
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
