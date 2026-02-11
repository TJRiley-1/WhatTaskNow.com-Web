import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatnow/core/widgets/glass_bottom_nav.dart';
import 'package:whatnow/core/constants/app_colors.dart';

void main() {
  group('GlassBottomNav', () {
    testWidgets('renders all 5 tab areas (4 nav items + 1 add button)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GlassBottomNav(
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );

      // 4 regular nav icons
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

      // Center add button
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('calls onTap with index 0 when home tab is tapped',
        (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GlassBottomNav(
              currentIndex: 1,
              onTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.home_rounded));
      expect(tappedIndex, 0);
    });

    testWidgets('calls onTap with index 1 when calendar tab is tapped',
        (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GlassBottomNav(
              currentIndex: 0,
              onTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.calendar_today_rounded));
      expect(tappedIndex, 1);
    });

    testWidgets('calls onTap with index 2 when add button is tapped',
        (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GlassBottomNav(
              currentIndex: 0,
              onTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(tappedIndex, 2);
    });

    testWidgets('calls onTap with index 3 when tasks tab is tapped',
        (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GlassBottomNav(
              currentIndex: 0,
              onTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.check_circle_outline_rounded));
      expect(tappedIndex, 3);
    });

    testWidgets('calls onTap with index 4 when profile tab is tapped',
        (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GlassBottomNav(
              currentIndex: 0,
              onTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      expect(tappedIndex, 4);
    });

    testWidgets('center add button is present with gradient decoration',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GlassBottomNav(
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );

      // The add button icon should be white and present
      final addIcon = tester.widget<Icon>(find.byIcon(Icons.add_rounded));
      expect(addIcon.color, Colors.white);
      expect(addIcon.size, 30);
    });

    testWidgets('selected tab has primary color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GlassBottomNav(
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );

      // Home is selected (index 0), so it should have primary color
      final homeIcon = tester.widget<Icon>(find.byIcon(Icons.home_rounded));
      expect(homeIcon.color, AppColors.primary);

      // Other tabs should have muted color
      final calendarIcon =
          tester.widget<Icon>(find.byIcon(Icons.calendar_today_rounded));
      expect(calendarIcon.color, AppColors.textMuted);
    });

    testWidgets('different selected index changes icon colors',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GlassBottomNav(
              currentIndex: 4,
              onTap: (_) {},
            ),
          ),
        ),
      );

      // Profile is selected (index 4)
      final profileIcon =
          tester.widget<Icon>(find.byIcon(Icons.person_outline_rounded));
      expect(profileIcon.color, AppColors.primary);

      // Home should be muted
      final homeIcon = tester.widget<Icon>(find.byIcon(Icons.home_rounded));
      expect(homeIcon.color, AppColors.textMuted);
    });
  });
}
