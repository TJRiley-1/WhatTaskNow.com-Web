import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whatnow/features/add_task/screens/add_type_screen.dart';
import 'package:whatnow/app.dart';
import 'package:whatnow/data/datasources/local/hive_datasource.dart';
import 'package:whatnow/data/datasources/remote/supabase_datasource.dart';
import 'package:whatnow/data/repositories/task_repository.dart';
import 'package:whatnow/data/models/task.dart';
import 'package:whatnow/data/models/completed_task.dart';
import 'package:whatnow/data/models/app_stats.dart';
import 'package:whatnow/data/models/template.dart';

/// A fake HiveDatasource for testing without Hive.
class FakeHiveDatasource extends HiveDatasource {
  @override
  List<Task> getTasks() => [];

  @override
  Task? getTask(String id) => null;

  @override
  AppStats getStats() => AppStats();

  @override
  List<CompletedTask> getCompletedTasks() => [];

  @override
  List<TaskTemplate> getTemplates() => [];

  @override
  List<String> getCustomTypes() => [];

  @override
  bool get isOnboardingComplete => true;

  @override
  bool get isPremium => false;
}

/// A fake SupabaseDatasource for testing without Supabase.
class FakeSupabaseDatasource extends SupabaseDatasource {}

void main() {
  group('Add Task Flow - Type Selection', () {
    late FakeHiveDatasource fakeHive;
    late FakeSupabaseDatasource fakeSupabase;
    late TaskRepository taskRepo;

    setUp(() {
      fakeHive = FakeHiveDatasource();
      fakeSupabase = FakeSupabaseDatasource();
      taskRepo = TaskRepository(fakeHive, fakeSupabase);
    });

    Widget buildTestableAddTypeScreen() {
      final router = GoRouter(
        initialLocation: '/add-type',
        routes: [
          GoRoute(
            path: '/add-type',
            builder: (context, state) => const AddTypeScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/add-time',
            builder: (context, state) =>
                const Scaffold(body: Text('Add Time')),
          ),
          GoRoute(
            path: '/templates',
            builder: (context, state) =>
                const Scaffold(body: Text('Templates')),
          ),
          GoRoute(
            path: '/multi-type',
            builder: (context, state) =>
                const Scaffold(body: Text('Multi Type')),
          ),
          GoRoute(
            path: '/import',
            builder: (context, state) =>
                const Scaffold(body: Text('Import')),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          hiveDatasourceProvider.overrideWithValue(fakeHive),
          taskRepositoryProvider.overrideWithValue(taskRepo),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('displays all 8 default task types', (tester) async {
      await tester.pumpWidget(buildTestableAddTypeScreen());
      await tester.pumpAndSettle();

      expect(find.text('Chores'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Errand'), findsOneWidget);
      expect(find.text('Self-care'), findsOneWidget);
      expect(find.text('Creative'), findsOneWidget);
      expect(find.text('Social'), findsOneWidget);
    });

    testWidgets('displays Add Custom Type option', (tester) async {
      await tester.pumpWidget(buildTestableAddTypeScreen());
      await tester.pumpAndSettle();

      expect(find.text('Add Custom Type'), findsOneWidget);
    });

    testWidgets('displays step indicator "1 of 6"', (tester) async {
      await tester.pumpWidget(buildTestableAddTypeScreen());
      await tester.pumpAndSettle();

      expect(find.text('1 of 6'), findsOneWidget);
    });

    testWidgets('displays screen title', (tester) async {
      await tester.pumpWidget(buildTestableAddTypeScreen());
      await tester.pumpAndSettle();

      expect(find.text('What type of task?'), findsOneWidget);
    });

    testWidgets('displays quick action buttons', (tester) async {
      await tester.pumpWidget(buildTestableAddTypeScreen());
      await tester.pumpAndSettle();

      expect(find.text('Saved Tasks'), findsOneWidget);
      expect(find.text('Multiple'), findsOneWidget);
      expect(find.text('Import'), findsOneWidget);
    });

    testWidgets('tapping a type updates newTaskProvider and navigates',
        (tester) async {
      await tester.pumpWidget(buildTestableAddTypeScreen());
      await tester.pumpAndSettle();

      // Tap on "Chores" type
      await tester.tap(find.text('Chores'));
      await tester.pumpAndSettle();

      // Should navigate to add-time screen
      expect(find.text('Add Time'), findsOneWidget);
    });

    testWidgets('tapping a different type also navigates to add-time',
        (tester) async {
      await tester.pumpWidget(buildTestableAddTypeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Health'));
      await tester.pumpAndSettle();

      expect(find.text('Add Time'), findsOneWidget);
    });

    testWidgets('tapping Saved Tasks navigates to templates', (tester) async {
      await tester.pumpWidget(buildTestableAddTypeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Saved Tasks'));
      await tester.pumpAndSettle();

      expect(find.text('Templates'), findsOneWidget);
    });
  });
}
