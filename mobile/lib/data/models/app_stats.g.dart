// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_stats.dart';

class AppStatsAdapter extends TypeAdapter<AppStats> {
  @override
  final int typeId = 4;

  @override
  AppStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppStats(
      completed: fields[0] as int,
      skipped: fields[1] as int,
      totalPoints: fields[2] as int,
      totalTimeSpent: fields[3] as int,
      pointsHistory: (fields[4] as List).cast<PointsEntry>(),
    );
  }

  @override
  void write(BinaryWriter writer, AppStats obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)..write(obj.completed)
      ..writeByte(1)..write(obj.skipped)
      ..writeByte(2)..write(obj.totalPoints)
      ..writeByte(3)..write(obj.totalTimeSpent)
      ..writeByte(4)..write(obj.pointsHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppStatsAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class PointsEntryAdapter extends TypeAdapter<PointsEntry> {
  @override
  final int typeId = 5;

  @override
  PointsEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PointsEntry(
      date: fields[0] as String,
      points: fields[1] as int,
      taskName: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PointsEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)..write(obj.date)
      ..writeByte(1)..write(obj.points)
      ..writeByte(2)..write(obj.taskName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointsEntryAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
