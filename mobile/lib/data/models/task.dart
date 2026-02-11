import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String type;

  @HiveField(4)
  int time; // minutes: 5, 15, 30, 60

  @HiveField(5)
  String social; // low, medium, high

  @HiveField(6)
  String energy; // low, medium, high

  @HiveField(7)
  String? dueDate; // ISO date string

  @HiveField(8)
  String recurring; // none, daily, weekly, monthly

  @HiveField(9)
  int timesShown;

  @HiveField(10)
  int timesSkipped;

  @HiveField(11)
  int timesCompleted;

  @HiveField(12)
  int pointsEarned;

  @HiveField(13)
  String createdAt;

  @HiveField(14)
  bool isFallback;

  @HiveField(15)
  bool needsSync; // dirty flag for offline-first

  Task({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.time,
    required this.social,
    required this.energy,
    this.dueDate,
    this.recurring = 'none',
    this.timesShown = 0,
    this.timesSkipped = 0,
    this.timesCompleted = 0,
    this.pointsEarned = 0,
    String? createdAt,
    this.isFallback = false,
    this.needsSync = true,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Task copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    int? time,
    String? social,
    String? energy,
    String? dueDate,
    String? recurring,
    int? timesShown,
    int? timesSkipped,
    int? timesCompleted,
    int? pointsEarned,
    String? createdAt,
    bool? isFallback,
    bool? needsSync,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      time: time ?? this.time,
      social: social ?? this.social,
      energy: energy ?? this.energy,
      dueDate: dueDate ?? this.dueDate,
      recurring: recurring ?? this.recurring,
      timesShown: timesShown ?? this.timesShown,
      timesSkipped: timesSkipped ?? this.timesSkipped,
      timesCompleted: timesCompleted ?? this.timesCompleted,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      createdAt: createdAt ?? this.createdAt,
      isFallback: isFallback ?? this.isFallback,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  /// Convert to map for Supabase upsert
  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'user_id': userId,
      'local_id': id,
      'name': name,
      'description': description,
      'type': type,
      'time': time,
      'social': social,
      'energy': energy,
      'due_date': dueDate,
      'recurring': recurring,
      'times_shown': timesShown,
      'times_skipped': timesSkipped,
      'times_completed': timesCompleted,
      'points_earned': pointsEarned,
    };
  }

  /// Create from Supabase row
  factory Task.fromSupabaseMap(Map<String, dynamic> map) {
    return Task(
      id: map['local_id'] ?? map['id'],
      name: map['name'],
      description: map['description'],
      type: map['type'],
      time: map['time'],
      social: map['social'],
      energy: map['energy'],
      dueDate: map['due_date'],
      recurring: map['recurring'] ?? 'none',
      timesShown: map['times_shown'] ?? 0,
      timesSkipped: map['times_skipped'] ?? 0,
      timesCompleted: map['times_completed'] ?? 0,
      pointsEarned: map['points_earned'] ?? 0,
      createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
      needsSync: false,
    );
  }
}
