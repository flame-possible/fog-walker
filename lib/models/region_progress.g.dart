// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'region_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RegionProgressAdapter extends TypeAdapter<RegionProgress> {
  @override
  final int typeId = 3;

  @override
  RegionProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RegionProgress(
      regionId: fields[0] as String,
      unlockedAt: fields[1] as DateTime,
      visitCount: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, RegionProgress obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.regionId)
      ..writeByte(1)
      ..write(obj.unlockedAt)
      ..writeByte(2)
      ..write(obj.visitCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegionProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
