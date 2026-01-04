import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blossom_app/features/onboarding/screens/onboarding_screen.dart';

// AdminAuthScreen requires a full Firebase environment to render because it checks auth state immediately.
// We verify OnboardingScreen here, which is the entry point for the "Run" request.

void main() {
  group('Screen Navigation Verification', () {
    testWidgets('Onboarding Screen renders correctly', (
      WidgetTester tester,
    ) async {
      // Build the Onboarding Screen
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

      // Verify the first slide text is present
      expect(find.textContaining('SPA only for'), findsOneWidget);

      // Verify "Login" button exists (navigates to LoginScreen)
      expect(find.text('Login'), findsOneWidget);

      // Verify "Sign Up" button exists (navigates to SignUpBasicInfoScreen)
      expect(find.text('Sign Up'), findsOneWidget);
    });
  });
}
