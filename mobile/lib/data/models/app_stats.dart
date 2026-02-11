import 'package:hive/hive.dart';

part 'app_stats.g.dart';

@HiveType(typeId: 4)
class AppStats extends HiveObject {
  @HiveField(0)
  int completed;

  @HiveField(1)
  int skipped;

  @HiveField(2)
  int totalPoints;

  @HiveField(3)
  int totalTimeSpent; // minutes

  @HiveField(4)
  List<PointsEntry> pointsHistory;

  AppStats({
    this.completed = 0,
    this.skipped = 0,
    this.totalPoints = 0,
    this.totalTimeSpent = 0,
    List<PointsEntry>? pointsHistory,
  }) : pointsHistory = pointsHistory ?? [];
}

@HiveType(typeId: 5)
class PointsEntry extends HiveObject {
  @HiveField(0)
  String date;

  @HiveField(1)
  int points;

  @HiveField(2)
  String taskName;

  PointsEntry({
    required this.date,
    required this.points,
    required this.taskName,
  });
}
