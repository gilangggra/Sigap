import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap/core/constants/app_dimensions.dart';
import 'package:sigap/shared/components/accessible_button.dart';

void main() {
  group('AccessibleButton Elderly Accessibility Tests', () {
    testWidgets('Tombol standar memenuhi batas target sentuh minimum lansia (min 64dp)', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Bantuan Warga',
              onPressed: () => pressed = true,
              isSimplified: false,
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(AccessibleButton);
      expect(buttonFinder, findsOneWidget);

      final RenderBox box = tester.renderObject(buttonFinder);
      expect(box.size.height, greaterThanOrEqualTo(AppDimensions.seniorMinTouchTarget)); // >= 64.0 dp

      await tester.tap(buttonFinder);
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('Tombol mode simplified (Care-Receiver) memenuhi batas rekomendasi lansia (min 72dp)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'PANGGIL BANTUAN SOS',
              onPressed: () {},
              isSimplified: true,
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(AccessibleButton);
      final RenderBox box = tester.renderObject(buttonFinder);
      expect(box.size.height, greaterThanOrEqualTo(AppDimensions.seniorRecommendedTouchTarget)); // >= 72.0 dp
    });
  });
}
