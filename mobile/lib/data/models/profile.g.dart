// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

class ProfileAdapter extends TypeAdapter<Profile> {
  @override
  final int typeId = 2;

  @override
  Profile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Profile(
      id: fields[0] as String,
      email: fields[1] as String?,
      displayName: fields[2] as String?,
      avatarUrl: fields[3] as String?,
      totalPoints: fields[4] as int,
      totalTasksCompleted: fields[5] as int,
      totalTimeSpent: fields[6] as int,
      currentRank: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Profile obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.email)
      ..writeByte(2)..write(obj.displayName)
      ..writeByte(3)..write(obj.avatarUrl)
      ..writeByte(4)..write(obj.totalPoints)
      ..writeByte(5)..write(obj.totalTasksCompleted)
      ..writeByte(6)..write(obj.totalTimeSpent)
      ..writeByte(7)..write(obj.currentRank);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
