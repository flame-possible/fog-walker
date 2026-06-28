// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 2;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      name: fields[0] as String,
      passportId: fields[1] as String,
      level: fields[2] as int,
      tier: fields[3] as String,
      stampCount: fields[4] as int,
      authProvider: fields[5] as AuthProviderType? ?? AuthProviderType.local,
      supabaseUserId: fields[6] as String?,
      email: fields[7] as String?,
      photoUrl: fields[8] as String?,
      displayName: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.passportId)
      ..writeByte(2)
      ..write(obj.level)
      ..writeByte(3)
      ..write(obj.tier)
      ..writeByte(4)
      ..write(obj.stampCount)
      ..writeByte(5)
      ..write(obj.authProvider)
      ..writeByte(6)
      ..write(obj.supabaseUserId)
      ..writeByte(7)
      ..write(obj.email)
      ..writeByte(8)
      ..write(obj.photoUrl)
      ..writeByte(9)
      ..write(obj.displayName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AuthProviderTypeAdapter extends TypeAdapter<AuthProviderType> {
  @override
  final int typeId = 4;

  @override
  AuthProviderType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AuthProviderType.local;
      case 1:
        return AuthProviderType.supabaseGoogle;
      default:
        return AuthProviderType.local;
    }
  }

  @override
  void write(BinaryWriter writer, AuthProviderType obj) {
    switch (obj) {
      case AuthProviderType.local:
        writer.writeByte(0);
        break;
      case AuthProviderType.supabaseGoogle:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthProviderTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
