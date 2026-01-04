import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blossom_app/core/constants/catalog_data.dart';
import 'package:blossom_app/core/constants/promotions_data.dart';
import 'package:blossom_app/common/widgets/text_input_dialog.dart';

void main() {
  group('Data Integrity Tests', () {
    test('CatalogData should have fallback data', () {
      expect(CatalogData.fallbackData, isNotEmpty);
      expect(CatalogData.fallbackData.containsKey('Body'), isTrue);
      expect(CatalogData.fallbackData['Body'], isNotNull);
      expect(CatalogData.fallbackData['Body']!.length, greaterThan(0));
      expect(CatalogData.fallbackData['Body']![0]['title'], isNotNull);
    });

    test('PromotionsData should have fallback data', () {
      expect(PromotionsData.fallbackPromotions, isNotEmpty);
      expect(PromotionsData.fallbackPromotions.length, greaterThan(0));
      expect(PromotionsData.fallbackPromotions[0]['title'], isNotNull);
    });
  });

  group('TextInputDialog Widget Tests', () {
    testWidgets('TextInputDialog renders correctly', (
      WidgetTester tester,
    ) async {
      // Create a key to identify the dialog
      const dialogKey = Key('test_dialog');
      String? confirmedValue;

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => TextInputDialog(
                      key: dialogKey,
                      title: 'Test Title',
                      initialValue: 'Initial',
                      hintText: 'Hint',
                      onConfirm: (value) async {
                        confirmedValue = value;
                      },
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap the button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify title and initial value
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Initial'), findsOneWidget);

      // Enter new text
      await tester.enterText(find.byType(TextField), 'New Value');
      await tester.pump();

      // Tap save
      await tester.tap(find.text('Save'));
      await tester.pump(); // Start async operation
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // Allow Future to complete if any

      // Verify callback was called (since our mock onConfirm is just a variable assignment, it should be quick)
      // Note: In the actual widget, there's async logic. The test might need to handle that.
      expect(confirmedValue, 'New Value');
    });
  });
}
