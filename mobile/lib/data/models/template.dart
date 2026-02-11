import 'package:hive/hive.dart';

part 'template.g.dart';

@HiveType(typeId: 6)
class TaskTemplate extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String type;

  @HiveField(4)
  int time;

  @HiveField(5)
  String social;

  @HiveField(6)
  String energy;

  @HiveField(7)
  String createdAt;

  TaskTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.time,
    required this.social,
    required this.energy,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();
}
