import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adm_ai/widgets/gradient_button.dart';

void main() {
  group('GradientButton', () {
    testWidgets('renders its label and an optional icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientButton(
              text: 'Yuborish',
              icon: Icons.send,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Yuborish'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('omits the icon when none is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientButton(text: 'Davom etish', onPressed: () {}),
          ),
        ),
      );

      expect(find.text('Davom etish'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('invokes onPressed when tapped', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientButton(
              text: 'Bosing',
              onPressed: () => tapCount++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GradientButton));
      await tester.pump();

      expect(tapCount, 1);
    });
  });
}
