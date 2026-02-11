import 'package:hive/hive.dart';

part 'profile.g.dart';

@HiveType(typeId: 2)
class Profile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? email;

  @HiveField(2)
  String? displayName;

  @HiveField(3)
  String? avatarUrl;

  @HiveField(4)
  int totalPoints;

  @HiveField(5)
  int totalTasksCompleted;

  @HiveField(6)
  int totalTimeSpent; // minutes

  @HiveField(7)
  String currentRank;

  Profile({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.totalPoints = 0,
    this.totalTasksCompleted = 0,
    this.totalTimeSpent = 0,
    this.currentRank = 'Task Newbie',
  });

  factory Profile.fromSupabaseMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      email: map['email'],
      displayName: map['display_name'],
      avatarUrl: map['avatar_url'],
      totalPoints: map['total_points'] ?? 0,
      totalTasksCompleted: map['total_tasks_completed'] ?? 0,
      totalTimeSpent: map['total_time_spent'] ?? 0,
      currentRank: map['current_rank'] ?? 'Task Newbie',
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'total_points': totalPoints,
      'total_tasks_completed': totalTasksCompleted,
      'total_time_spent': totalTimeSpent,
      'current_rank': currentRank,
    };
  }
}
