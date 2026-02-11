import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatnow/core/widgets/screen_scaffold.dart';

void main() {
  group('ScreenScaffold', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScreenScaffold(
            title: 'Test Title',
            body: SizedBox(),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('renders body content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScreenScaffold(
            title: 'Title',
            body: Text('Body Content'),
          ),
        ),
      );

      expect(find.text('Body Content'), findsOneWidget);
    });

    testWidgets('shows back button when onBack is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScreenScaffold(
            title: 'Title',
            body: const SizedBox(),
            onBack: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });

    testWidgets('does not show back button when onBack is null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScreenScaffold(
            title: 'Title',
            body: SizedBox(),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });

    testWidgets('calls onBack when back button is tapped', (tester) async {
      var backPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ScreenScaffold(
            title: 'Title',
            body: const SizedBox(),
            onBack: () => backPressed = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump();
      expect(backPressed, true);
    });

    testWidgets('shows step indicator when stepIndicator is provided',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScreenScaffold(
            title: 'Title',
            body: SizedBox(),
            stepIndicator: '2 of 6',
          ),
        ),
      );

      expect(find.text('2 of 6'), findsOneWidget);
    });

    testWidgets('shows step indicator with different values', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScreenScaffold(
            title: 'Title',
            body: SizedBox(),
            stepIndicator: '1 of 6',
          ),
        ),
      );

      expect(find.text('1 of 6'), findsOneWidget);
    });

    testWidgets('does not show step indicator when not provided',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScreenScaffold(
            title: 'Title',
            body: SizedBox(),
          ),
        ),
      );

      // Ensure no step indicator text is present
      expect(find.text('1 of 6'), findsNothing);
      expect(find.text('2 of 6'), findsNothing);
    });

    testWidgets('renders custom actions when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScreenScaffold(
            title: 'Title',
            body: const SizedBox(),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('renders both step indicator and actions together',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScreenScaffold(
            title: 'Title',
            body: const SizedBox(),
            stepIndicator: '3 of 6',
            actions: [
              IconButton(
                icon: const Icon(Icons.help),
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.text('3 of 6'), findsOneWidget);
      expect(find.byIcon(Icons.help), findsOneWidget);
    });

    testWidgets('wraps body in SafeArea', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScreenScaffold(
            title: 'Title',
            body: Text('Safe Body'),
          ),
        ),
      );

      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.text('Safe Body'), findsOneWidget);
    });
  });
}
