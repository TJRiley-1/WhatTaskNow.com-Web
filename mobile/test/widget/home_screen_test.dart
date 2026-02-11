import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whatnow/features/home/screens/home_screen.dart';
import 'package:whatnow/app.dart';
import 'package:whatnow/data/datasources/local/hive_datasource.dart';
import 'package:whatnow/data/datasources/remote/supabase_datasource.dart';
import 'package:whatnow/data/repositories/task_repository.dart';
import 'package:whatnow/data/models/task.dart';
import 'package:whatnow/data/models/completed_task.dart';
import 'package:whatnow/data/models/app_stats.dart';
import 'package:whatnow/data/models/template.dart';

/// A fake HiveDatasource that does not require Hive initialization.
class FakeHiveDatasource extends HiveDatasource {
  final List<Task> _tasks;
  final AppStats _stats;

  FakeHiveDatasource({
    List<Task>? tasks,
    AppStats? stats,
  })  : _tasks = tasks ?? [],
        _stats = stats ?? AppStats();

  @override
  List<Task> getTasks() => _tasks;

  @override
  Task? getTask(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  AppStats getStats() => _stats;

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

/// A fake SupabaseDatasource that does not require Supabase initialization.
class FakeSupabaseDatasource extends SupabaseDatasource {}

/// Builds a testable widget with ProviderScope overrides for HomeScreen.
Widget buildTestableHomeScreen({
  List<Task>? tasks,
  AppStats? stats,
}) {
  final fakeHive = FakeHiveDatasource(tasks: tasks, stats: stats);
  final fakeSupabase = FakeSupabaseDatasource();
  final taskRepo = TaskRepository(fakeHive, fakeSupabase);

  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      // Stub routes so navigation doesn't fail
      GoRoute(
        path: '/add-type',
        builder: (context, state) =>
            const Scaffold(body: Text('Add Type')),
      ),
      GoRoute(
        path: '/state',
        builder: (context, state) =>
            const Scaffold(body: Text('State Screen')),
      ),
      GoRoute(
        path: '/manage',
        builder: (context, state) =>
            const Scaffold(body: Text('Manage')),
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

void main() {
  group('HomeScreen', () {
    testWidgets('renders the rank display', (tester) async {
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      // Default 0 points = Task Newbie
      expect(find.text('Task Newbie'), findsOneWidget);
    });

    testWidgets('renders correct rank for higher points', (tester) async {
      await tester.pumpWidget(
        buildTestableHomeScreen(stats: AppStats(totalPoints: 500)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Task Warrior'), findsOneWidget);
    });

    testWidgets('has Add Task button', (tester) async {
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('Add Task'), findsOneWidget);
    });

    testWidgets('has What Next button', (tester) async {
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('What Next'), findsOneWidget);
    });

    testWidgets('has Manage Tasks link', (tester) async {
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('Manage Tasks'), findsOneWidget);
    });

    testWidgets('shows the app title "What Now?"', (tester) async {
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('What Now?'), findsOneWidget);
    });

    testWidgets('shows the subtitle text', (tester) async {
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('Stop overthinking. Start doing.'), findsOneWidget);
    });

    testWidgets('shows points display for newbie', (tester) async {
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      // 0 / 100 points (next rank is Apprentice at 100)
      expect(find.text('0 / 100 points'), findsOneWidget);
    });

    testWidgets('shows next rank indicator', (tester) async {
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('Next: Task Apprentice'), findsOneWidget);
    });

    testWidgets('Add Task button is tappable', (tester) async {
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      // Just verify tapping doesn't throw
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();
    });

    testWidgets('What Next button is tappable', (tester) async {
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('What Next'));
      await tester.pumpAndSettle();
    });

    testWidgets('shows max rank message for Legend', (tester) async {
      await tester.pumpWidget(
        buildTestableHomeScreen(stats: AppStats(totalPoints: 5000)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Task Legend'), findsOneWidget);
      expect(find.text('5000 points - Max rank!'), findsOneWidget);
    });
  });
}
