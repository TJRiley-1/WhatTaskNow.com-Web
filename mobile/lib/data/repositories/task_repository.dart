import 'package:uuid/uuid.dart';
import '../datasources/local/hive_datasource.dart';
import '../datasources/remote/supabase_datasource.dart';
import '../models/task.dart';
import '../models/completed_task.dart';
import '../models/app_stats.dart';
import '../models/template.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/points_calculator.dart';

class TaskRepository {
  final HiveDatasource _local;
  final SupabaseDatasource _remote;
  static const _uuid = Uuid();

  TaskRepository(this._local, this._remote);

  // --- Tasks ---

  List<Task> getTasks() => _local.getTasks();

  int get taskCount => _local.getTasks().length;

  bool get canAddTask => _local.isPremium || taskCount < kFreeTaskLimit;

  Task addTask({
    required String name,
    String? description,
    required String type,
    required int time,
    required String social,
    required String energy,
    String? dueDate,
    String recurring = 'none',
  }) {
    final task = Task(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}',
      name: name,
      description: description,
      type: type,
      time: time,
      social: social,
      energy: energy,
      dueDate: dueDate,
      recurring: recurring,
    );
    _local.addTask(task);
    return task;
  }

  void updateTask(String id, Map<String, dynamic> updates) {
    final task = _local.getTask(id);
    if (task == null) return;

    final updated = task.copyWith(
      name: updates['name'] as String? ?? task.name,
      description: updates['description'] as String? ?? task.description,
      type: updates['type'] as String? ?? task.type,
      time: updates['time'] as int? ?? task.time,
      social: updates['social'] as String? ?? task.social,
      energy: updates['energy'] as String? ?? task.energy,
      dueDate: updates['dueDate'] as String? ?? task.dueDate,
      recurring: updates['recurring'] as String? ?? task.recurring,
      timesShown: updates['timesShown'] as int? ?? task.timesShown,
      timesSkipped: updates['timesSkipped'] as int? ?? task.timesSkipped,
      timesCompleted: updates['timesCompleted'] as int? ?? task.timesCompleted,
      pointsEarned: updates['pointsEarned'] as int? ?? task.pointsEarned,
      needsSync: true,
    );
    _local.updateTask(updated);
  }

  void deleteTask(String id) {
    _local.deleteTask(id);
  }

  /// Find matching tasks based on current state.
  /// Null values mean "match all" on that dimension.
  List<Task> findMatchingTasks({String? energy, String? social, int? time}) {
    final tasks = _local.getTasks();

    final matching = tasks.where((task) {
      final energyMatch = energy == null ||
          (kEnergyLevels[energy] ?? 0) >= (kEnergyLevels[task.energy] ?? 0);
      final socialMatch = social == null ||
          (kSocialLevels[social] ?? 0) >= (kSocialLevels[task.social] ?? 0);
      final timeMatch = time == null || time >= task.time;
      return energyMatch && socialMatch && timeMatch;
    }).toList();

    matching.sort((a, b) {
      final urgencyDiff = getUrgencyScore(b) - getUrgencyScore(a);
      if (urgencyDiff != 0) return urgencyDiff;
      final skipDiff = b.timesSkipped - a.timesSkipped;
      if (skipDiff != 0) return skipDiff;
      return a.timesShown - b.timesShown;
    });

    return matching;
  }

  /// Get fallback tasks that match current state
  List<Task> getFallbackTasks({String? energy, String? social, int? time}) {
    return kFallbackTasks.where((t) {
      final energyMatch = energy == null ||
          (kEnergyLevels[energy] ?? 0) >= (kEnergyLevels[t['energy'] as String] ?? 0);
      final socialMatch = social == null ||
          (kSocialLevels[social] ?? 0) >= (kSocialLevels[t['social'] as String] ?? 0);
      final timeMatch = time == null || time >= (t['time'] as int);
      return energyMatch && socialMatch && timeMatch;
    }).map((t) => Task(
          id: 'fallback_${_uuid.v4().substring(0, 8)}',
          name: t['name'] as String,
          description: t['desc'] as String?,
          type: t['type'] as String,
          time: t['time'] as int,
          social: t['social'] as String,
          energy: t['energy'] as String,
          isFallback: true,
          needsSync: false,
        )).toList();
  }

  // --- Completed Tasks ---

  CompletedTask completeTask(Task task, {int? timeSpentMinutes}) {
    final points = calculatePoints(task);

    // Update task stats
    if (!task.isFallback) {
      updateTask(task.id, {
        'timesCompleted': task.timesCompleted + 1,
        'pointsEarned': task.pointsEarned + points,
      });

      // Handle recurring
      if (task.recurring != 'none') {
        final nextDue = getNextDueDate(task);
        if (nextDue != null) {
          updateTask(task.id, {'dueDate': nextDue});
        }
      }
    }

    // Add completed record
    final completed = CompletedTask(
      id: 'cpl_${DateTime.now().millisecondsSinceEpoch}',
      name: task.name,
      type: task.type,
      points: points,
      timeSpent: timeSpentMinutes,
    );
    _local.addCompletedTask(completed);

    // Update stats
    final stats = _local.getStats();
    stats.completed++;
    stats.totalPoints += points;
    if (timeSpentMinutes != null) {
      stats.totalTimeSpent += timeSpentMinutes;
    }
    stats.pointsHistory.add(PointsEntry(
      date: DateTime.now().toIso8601String(),
      points: points,
      taskName: task.name,
    ));
    if (stats.pointsHistory.length > 100) {
      stats.pointsHistory = stats.pointsHistory.sublist(stats.pointsHistory.length - 100);
    }
    _local.saveStats(stats);

    return completed;
  }

  void skipTask(Task task) {
    if (!task.isFallback) {
      updateTask(task.id, {
        'timesShown': task.timesShown + 1,
        'timesSkipped': task.timesSkipped + 1,
      });
    }

    final stats = _local.getStats();
    stats.skipped++;
    _local.saveStats(stats);
  }

  void markTaskShown(Task task) {
    if (!task.isFallback) {
      updateTask(task.id, {'timesShown': task.timesShown + 1});
    }
  }

  List<CompletedTask> getCompletedTasks() => _local.getCompletedTasks();

  AppStats getStats() => _local.getStats();

  // --- Templates ---

  List<TaskTemplate> getTemplates() => _local.getTemplates();

  void addTemplate(TaskTemplate template) => _local.addTemplate(template);

  void deleteTemplate(String id) => _local.deleteTemplate(id);

  TaskTemplate createTemplate({
    required String name,
    String? description,
    required String type,
    required int time,
    required String social,
    required String energy,
  }) {
    final template = TaskTemplate(
      id: 'tpl_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      type: type,
      time: time,
      social: social,
      energy: energy,
    );
    _local.addTemplate(template);
    return template;
  }

  // --- Custom Types ---

  List<String> getTaskTypes() {
    return [...kDefaultTypes, ..._local.getCustomTypes()];
  }

  void addCustomType(String type) => _local.addCustomType(type);

  void removeCustomType(String type) => _local.removeCustomType(type);
}
