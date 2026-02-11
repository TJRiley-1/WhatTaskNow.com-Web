import 'package:hive_flutter/hive_flutter.dart';
import '../../models/task.dart';
import '../../models/completed_task.dart';
import '../../models/profile.dart';
import '../../models/group.dart';
import '../../models/app_stats.dart';
import '../../models/template.dart';

class HiveDatasource {
  static const String tasksBox = 'tasks';
  static const String completedBox = 'completed_tasks';
  static const String templatesBox = 'templates';
  static const String statsBox = 'stats';
  static const String settingsBox = 'settings';
  static const String customTypesBox = 'custom_types';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(CompletedTaskAdapter());
    Hive.registerAdapter(ProfileAdapter());
    Hive.registerAdapter(GroupAdapter());
    Hive.registerAdapter(AppStatsAdapter());
    Hive.registerAdapter(PointsEntryAdapter());
    Hive.registerAdapter(TaskTemplateAdapter());

    // Open boxes
    await Hive.openBox<Task>(tasksBox);
    await Hive.openBox<CompletedTask>(completedBox);
    await Hive.openBox<TaskTemplate>(templatesBox);
    await Hive.openBox(statsBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox<String>(customTypesBox);
  }

  // --- Tasks ---
  Box<Task> get _taskBox => Hive.box<Task>(tasksBox);

  List<Task> getTasks() => _taskBox.values.toList();

  Task? getTask(String id) {
    try {
      return _taskBox.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addTask(Task task) async {
    await _taskBox.put(task.id, task);
  }

  Future<void> updateTask(Task task) async {
    await _taskBox.put(task.id, task);
  }

  Future<void> deleteTask(String id) async {
    await _taskBox.delete(id);
  }

  List<Task> getDirtyTasks() =>
      _taskBox.values.where((t) => t.needsSync).toList();

  Future<void> replaceAllTasks(List<Task> tasks) async {
    await _taskBox.clear();
    for (final task in tasks) {
      await _taskBox.put(task.id, task);
    }
  }

  // --- Completed Tasks ---
  Box<CompletedTask> get _completedBox => Hive.box<CompletedTask>(completedBox);

  List<CompletedTask> getCompletedTasks() => _completedBox.values.toList();

  Future<void> addCompletedTask(CompletedTask task) async {
    await _completedBox.put(task.id, task);
    // Keep only last 200
    if (_completedBox.length > 200) {
      final keys = _completedBox.keys.toList();
      for (var i = 0; i < keys.length - 200; i++) {
        await _completedBox.delete(keys[i]);
      }
    }
  }

  List<CompletedTask> getDirtyCompletedTasks() =>
      _completedBox.values.where((t) => t.needsSync).toList();

  // --- Templates ---
  Box<TaskTemplate> get _templateBox => Hive.box<TaskTemplate>(templatesBox);

  List<TaskTemplate> getTemplates() => _templateBox.values.toList();

  Future<void> addTemplate(TaskTemplate template) async {
    await _templateBox.put(template.id, template);
  }

  Future<void> deleteTemplate(String id) async {
    await _templateBox.delete(id);
  }

  // --- Stats ---
  Box get _statsBox => Hive.box(statsBox);

  AppStats getStats() {
    final raw = _statsBox.get('stats');
    if (raw is AppStats) return raw;
    return AppStats();
  }

  Future<void> saveStats(AppStats stats) async {
    await _statsBox.put('stats', stats);
  }

  // --- Settings ---
  Box get _settingsBox => Hive.box(settingsBox);

  T? getSetting<T>(String key) => _settingsBox.get(key) as T?;

  Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  bool get isOnboardingComplete =>
      _settingsBox.get('onboarding_complete', defaultValue: false) as bool;

  Future<void> setOnboardingComplete() async {
    await _settingsBox.put('onboarding_complete', true);
  }

  bool get isPremium =>
      _settingsBox.get('is_premium', defaultValue: false) as bool;

  Future<void> setPremium(bool value) async {
    await _settingsBox.put('is_premium', value);
  }

  bool get biometricEnabled =>
      _settingsBox.get('biometric_enabled', defaultValue: false) as bool;

  Future<void> setBiometricEnabled(bool value) async {
    await _settingsBox.put('biometric_enabled', value);
  }

  // --- Custom Types ---
  Box<String> get _typesBox => Hive.box<String>(customTypesBox);

  List<String> getCustomTypes() => _typesBox.values.toList();

  Future<void> addCustomType(String type) async {
    if (!_typesBox.values.contains(type)) {
      await _typesBox.add(type);
    }
  }

  Future<void> removeCustomType(String type) async {
    final key = _typesBox.keys.firstWhere(
      (k) => _typesBox.get(k) == type,
      orElse: () => null,
    );
    if (key != null) {
      await _typesBox.delete(key);
    }
  }
}
