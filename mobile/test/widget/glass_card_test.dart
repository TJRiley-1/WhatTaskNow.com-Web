import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatnow/core/widgets/glass_card.dart';

void main() {
  group('GlassCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('responds to tap when onTap provided', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              onTap: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      expect(tapped, true);
    });

    testWidgets('does not respond to tap when onTap is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('No Tap'),
            ),
          ),
        ),
      );

      // Should not find a GestureDetector wrapping it
      expect(find.byType(GestureDetector), findsNothing);
    });
  });

  group('GlassOptionCard', () {
    testWidgets('renders label and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassOptionCard(
              label: 'Low',
              subtitle: 'Solo, no interaction',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Solo, no interaction'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassOptionCard(
              label: 'Option',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Option'));
      expect(tapped, true);
    });
  });
}
