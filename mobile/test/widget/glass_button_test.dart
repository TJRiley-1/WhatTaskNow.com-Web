import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatnow/core/widgets/glass_button.dart';

void main() {
  group('GlassButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              label: 'Click Me',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              label: 'Tap Test',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Test'));
      await tester.pump();
      expect(pressed, true);
    });

    testWidgets('shows CircularProgressIndicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              label: 'Loading',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsOneWidget);
    });

    testWidgets('does not show CircularProgressIndicator when not loading',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              label: 'Not Loading',
              onPressed: () {},
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('does not respond to tap when isLoading is true',
        (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              label: 'Loading Tap',
              onPressed: () => pressed = true,
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Loading Tap'));
      await tester.pump();
      expect(pressed, false);
    });

    testWidgets('disabled state (onPressed null) does not respond to tap',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassButton(
              label: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );

      // The button should render but tapping should do nothing (no crash)
      expect(find.text('Disabled'), findsOneWidget);
      await tester.tap(find.text('Disabled'));
      await tester.pump();
      // No exception means it handled null onPressed correctly
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              label: 'With Icon',
              onPressed: () {},
              icon: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('With Icon'), findsOneWidget);
    });

    testWidgets('does not render icon when isLoading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              label: 'Loading Icon',
              onPressed: () {},
              icon: const Icon(Icons.add),
              isLoading: true,
            ),
          ),
        ),
      );

      // When loading, icon is replaced by CircularProgressIndicator
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('primary variant renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              label: 'Primary',
              onPressed: () {},
              variant: GlassButtonVariant.primary,
            ),
          ),
        ),
      );

      expect(find.text('Primary'), findsOneWidget);
      // Verify text is rendered with white color for primary variant
      final textWidget = tester.widget<Text>(find.text('Primary'));
      expect(textWidget.style?.color, Colors.white);
    });

    testWidgets('secondary variant renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              label: 'Secondary',
              onPressed: () {},
              variant: GlassButtonVariant.secondary,
            ),
          ),
        ),
      );

      expect(find.text('Secondary'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('Secondary'));
      expect(textWidget.style?.color, Colors.white);
    });

    testWidgets('isLarge increases font size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              label: 'Large',
              onPressed: () {},
              isLarge: true,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Large'));
      expect(textWidget.style?.fontSize, 18);
    });

    testWidgets('default size has smaller font', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              label: 'Normal',
              onPressed: () {},
              isLarge: false,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Normal'));
      expect(textWidget.style?.fontSize, 16);
    });
  });
}
