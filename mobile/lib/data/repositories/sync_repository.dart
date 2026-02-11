import 'package:connectivity_plus/connectivity_plus.dart';
import '../datasources/local/hive_datasource.dart';
import '../datasources/remote/supabase_datasource.dart';
import '../models/task.dart';

class SyncRepository {
  final HiveDatasource _local;
  final SupabaseDatasource _remote;

  SyncRepository(this._local, this._remote);

  /// Check if we have network connectivity
  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Full sync: push dirty local data, pull remote data
  Future<void> fullSync() async {
    final userId = _remote.userId;
    if (userId == null) return;
    if (!await isOnline) return;

    // Push dirty tasks
    final dirtyTasks = _local.getDirtyTasks();
    if (dirtyTasks.isNotEmpty) {
      await _remote.syncTasks(userId, dirtyTasks);
      // Mark as clean
      for (final task in dirtyTasks) {
        await _local.updateTask(task.copyWith(needsSync: false));
      }
    }

    // Push dirty completed tasks
    final dirtyCompleted = _local.getDirtyCompletedTasks();
    for (final completed in dirtyCompleted) {
      await _remote.logCompleted(userId, completed);
      completed.needsSync = false;
      await _local.addCompletedTask(completed);
    }

    // Pull remote tasks and merge
    final remoteTasks = await _remote.getTasks(userId);
    final localTasks = _local.getTasks();
    final localIds = localTasks.map((t) => t.id).toSet();

    for (final remote in remoteTasks) {
      if (!localIds.contains(remote.id)) {
        await _local.addTask(remote);
      }
    }

    // Update profile stats from local
    final stats = _local.getStats();
    await _remote.updateProfile(userId, {
      'total_points': stats.totalPoints,
      'total_tasks_completed': stats.completed,
      'total_time_spent': stats.totalTimeSpent,
    });
  }

  /// Push a single task to remote
  Future<void> pushTask(Task task) async {
    final userId = _remote.userId;
    if (userId == null) return;
    if (!await isOnline) return;

    await _remote.syncTasks(userId, [task]);
    await _local.updateTask(task.copyWith(needsSync: false));
  }

  /// Stream connectivity changes
  Stream<bool> get connectivityStream {
    return Connectivity().onConnectivityChanged.map(
      (result) => !result.contains(ConnectivityResult.none),
    );
  }
}
