import 'package:flutter_test/flutter_test.dart';
import 'package:blossom_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the Onboarding Screen is displayed.
    // We look for the first slide's text.
    // Note: The text contains a newline, so we might need to match partial text or handle the newline.
    expect(find.textContaining('SPA only for'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });
}
