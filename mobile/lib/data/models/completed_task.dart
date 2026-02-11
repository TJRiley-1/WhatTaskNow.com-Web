import 'package:hive/hive.dart';

part 'completed_task.g.dart';

@HiveType(typeId: 1)
class CompletedTask extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type;

  @HiveField(3)
  int points;

  @HiveField(4)
  int? timeSpent; // minutes

  @HiveField(5)
  String completedAt;

  @HiveField(6)
  bool needsSync;

  CompletedTask({
    required this.id,
    required this.name,
    required this.type,
    required this.points,
    this.timeSpent,
    String? completedAt,
    this.needsSync = true,
  }) : completedAt = completedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'user_id': userId,
      'task_name': name,
      'task_type': type,
      'points': points,
      'time_spent': timeSpent,
    };
  }

  factory CompletedTask.fromSupabaseMap(Map<String, dynamic> map) {
    return CompletedTask(
      id: map['id'],
      name: map['task_name'],
      type: map['task_type'],
      points: map['points'],
      timeSpent: map['time_spent'],
      completedAt: map['completed_at'] ?? DateTime.now().toIso8601String(),
      needsSync: false,
    );
  }
}
