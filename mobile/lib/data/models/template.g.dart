// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template.dart';

class TaskTemplateAdapter extends TypeAdapter<TaskTemplate> {
  @override
  final int typeId = 6;

  @override
  TaskTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      type: fields[3] as String,
      time: fields[4] as int,
      social: fields[5] as String,
      energy: fields[6] as String,
      createdAt: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TaskTemplate obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.description)
      ..writeByte(3)..write(obj.type)
      ..writeByte(4)..write(obj.time)
      ..writeByte(5)..write(obj.social)
      ..writeByte(6)..write(obj.energy)
      ..writeByte(7)..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTemplateAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
