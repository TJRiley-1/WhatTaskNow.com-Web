import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/datasources/local/hive_datasource.dart';
import 'data/datasources/remote/supabase_datasource.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/sync_repository.dart';
import 'data/repositories/subscription_repository.dart';

// --- Providers ---

final hiveDatasourceProvider = Provider<HiveDatasource>((ref) => HiveDatasource());
final supabaseDatasourceProvider = Provider<SupabaseDatasource>((ref) => SupabaseDatasource());

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    ref.read(hiveDatasourceProvider),
    ref.read(supabaseDatasourceProvider),
  );
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
    ref.read(hiveDatasourceProvider),
    ref.read(supabaseDatasourceProvider),
  );
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.read(hiveDatasourceProvider));
});

// --- State Providers ---

/// Tracks the new task being built in the add-task wizard
final newTaskProvider = StateProvider<Map<String, dynamic>>((ref) => {});

/// Tracks the multi-add task settings
final multiAddTaskProvider = StateProvider<Map<String, dynamic>>((ref) => {});

/// Tracks current state selection for What Next flow
final currentStateProvider = StateProvider<Map<String, dynamic>>((ref) => {
      'energy': null,
      'social': null,
      'time': null,
    });

/// Matching tasks for the swipe flow
final matchingTasksProvider = StateProvider<List<dynamic>>((ref) => []);

/// Current card index in the swipe flow
final currentCardIndexProvider = StateProvider<int>((ref) => 0);

/// The currently accepted task
final acceptedTaskProvider = StateProvider<dynamic>((ref) => null);

/// Timer state
final timerSecondsProvider = StateProvider<int>((ref) => 0);
final timerRunningProvider = StateProvider<bool>((ref) => false);

/// Last points earned (for celebration screen)
final lastPointsEarnedProvider = StateProvider<int>((ref) => 0);

/// Previous rank (for rank-up detection)
final previousRankProvider = StateProvider<String?>((ref) => null);

/// Pending imports
final pendingImportsProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

/// Import task settings being configured
final importTaskSettingsProvider = StateProvider<Map<String, dynamic>>((ref) => {});

/// Current import task being configured
final currentImportTaskProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

/// Current group being viewed
final currentGroupProvider = StateProvider<dynamic>((ref) => null);

class WhatNowApp extends ConsumerWidget {
  const WhatNowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hive = ref.read(hiveDatasourceProvider);
    final router = createRouter(isOnboardingComplete: hive.isOnboardingComplete);

    return MaterialApp.router(
      title: 'What Now?',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
