import 'package:hive/hive.dart';

part 'group.g.dart';

@HiveType(typeId: 3)
class Group extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String inviteCode;

  @HiveField(4)
  String? createdBy;

  @HiveField(5)
  String createdAt;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.inviteCode,
    this.createdBy,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory Group.fromSupabaseMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      inviteCode: map['invite_code'],
      createdBy: map['created_by'],
      createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }
}
