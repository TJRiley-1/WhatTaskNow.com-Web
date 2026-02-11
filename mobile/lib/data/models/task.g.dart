// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter packages pub run build_runner build

part of 'task.dart';

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      type: fields[3] as String,
      time: fields[4] as int,
      social: fields[5] as String,
      energy: fields[6] as String,
      dueDate: fields[7] as String?,
      recurring: fields[8] as String,
      timesShown: fields[9] as int,
      timesSkipped: fields[10] as int,
      timesCompleted: fields[11] as int,
      pointsEarned: fields[12] as int,
      createdAt: fields[13] as String,
      isFallback: fields[14] as bool,
      needsSync: fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.description)
      ..writeByte(3)..write(obj.type)
      ..writeByte(4)..write(obj.time)
      ..writeByte(5)..write(obj.social)
      ..writeByte(6)..write(obj.energy)
      ..writeByte(7)..write(obj.dueDate)
      ..writeByte(8)..write(obj.recurring)
      ..writeByte(9)..write(obj.timesShown)
      ..writeByte(10)..write(obj.timesSkipped)
      ..writeByte(11)..write(obj.timesCompleted)
      ..writeByte(12)..write(obj.pointsEarned)
      ..writeByte(13)..write(obj.createdAt)
      ..writeByte(14)..write(obj.isFallback)
      ..writeByte(15)..write(obj.needsSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
