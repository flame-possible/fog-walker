// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'walk_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WalkSessionAdapter extends TypeAdapter<WalkSession> {
  @override
  final int typeId = 0;

  @override
  WalkSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WalkSession(
      id: fields[0] as String,
      startedAt: fields[1] as DateTime,
      endedAt: fields[2] as DateTime,
      distanceKm: fields[3] as double,
      clearedKm2: fields[4] as double,
      newCellsCount: fields[5] as int,
      regionIds: (fields[6] as List).cast<String>(),
      mode: fields[7] as WalkMode,
    );
  }

  @override
  void write(BinaryWriter writer, WalkSession obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startedAt)
      ..writeByte(2)
      ..write(obj.endedAt)
      ..writeByte(3)
      ..write(obj.distanceKm)
      ..writeByte(4)
      ..write(obj.clearedKm2)
      ..writeByte(5)
      ..write(obj.newCellsCount)
      ..writeByte(6)
      ..write(obj.regionIds)
      ..writeByte(7)
      ..write(obj.mode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalkSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WalkModeAdapter extends TypeAdapter<WalkMode> {
  @override
  final int typeId = 1;

  @override
  WalkMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WalkMode.walk;
      case 1:
        return WalkMode.bike;
      case 2:
        return WalkMode.swim;
      case 3:
        return WalkMode.hike;
      default:
        return WalkMode.walk;
    }
  }

  @override
  void write(BinaryWriter writer, WalkMode obj) {
    switch (obj) {
      case WalkMode.walk:
        writer.writeByte(0);
        break;
      case WalkMode.bike:
        writer.writeByte(1);
        break;
      case WalkMode.swim:
        writer.writeByte(2);
        break;
      case WalkMode.hike:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalkModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
