import '../models/region_progress.dart';
import '../models/user_profile.dart';
import '../models/walk_session.dart';

DateTime _dateFromRow(Object? value) {
  if (value is DateTime) return value.toUtc();
  if (value is String) return DateTime.parse(value).toUtc();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value).toUtc();
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

double _doubleFromRow(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _intFromRow(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<String> _stringListFromRow(Object? value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  return const [];
}

class SyncVisitedCell {
  const SyncVisitedCell({required this.cell, required this.visitedAtMillis});

  final (int, int) cell;
  final int visitedAtMillis;

  factory SyncVisitedCell.fromRow(Map<String, dynamic> row) {
    final visitedAt = _dateFromRow(row['visited_at']);
    return SyncVisitedCell(
      cell: (_intFromRow(row['cell_x']), _intFromRow(row['cell_y'])),
      visitedAtMillis: visitedAt.millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'cell_x': cell.$1,
      'cell_y': cell.$2,
      'visited_at': DateTime.fromMillisecondsSinceEpoch(
        visitedAtMillis,
        isUtc: true,
      ).toIso8601String(),
    };
  }
}

class SyncWalkSession {
  const SyncWalkSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.clearedKm2,
    required this.newCellsCount,
    required this.regionIds,
  });

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceKm;
  final double clearedKm2;
  final int newCellsCount;
  final List<String> regionIds;

  factory SyncWalkSession.fromModel(WalkSession session) {
    return SyncWalkSession(
      id: session.id,
      startedAt: session.startedAt.toUtc(),
      endedAt: session.endedAt.toUtc(),
      distanceKm: session.distanceKm,
      clearedKm2: session.clearedKm2,
      newCellsCount: session.newCellsCount,
      regionIds: session.regionIds,
    );
  }

  factory SyncWalkSession.fromRow(Map<String, dynamic> row) {
    return SyncWalkSession(
      id: row['id'].toString(),
      startedAt: _dateFromRow(row['started_at']),
      endedAt: _dateFromRow(row['ended_at']),
      distanceKm: _doubleFromRow(row['distance_km']),
      clearedKm2: _doubleFromRow(row['cleared_km2']),
      newCellsCount: _intFromRow(row['new_cells_count']),
      regionIds: _stringListFromRow(row['region_ids']),
    );
  }

  WalkSession toModel() {
    return WalkSession(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt,
      distanceKm: distanceKm,
      clearedKm2: clearedKm2,
      newCellsCount: newCellsCount,
      regionIds: regionIds,
      mode: WalkMode.walk,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'started_at': startedAt.toUtc().toIso8601String(),
      'ended_at': endedAt.toUtc().toIso8601String(),
      'distance_km': distanceKm,
      'cleared_km2': clearedKm2,
      'new_cells_count': newCellsCount,
      'region_ids': regionIds,
    };
  }
}

class SyncRegionProgress {
  const SyncRegionProgress({
    required this.regionId,
    required this.unlockedAt,
    required this.visitCount,
  });

  final String regionId;
  final DateTime unlockedAt;
  final int visitCount;

  factory SyncRegionProgress.fromModel(RegionProgress progress) {
    return SyncRegionProgress(
      regionId: progress.regionId,
      unlockedAt: progress.unlockedAt.toUtc(),
      visitCount: progress.visitCount,
    );
  }

  factory SyncRegionProgress.fromRow(Map<String, dynamic> row) {
    return SyncRegionProgress(
      regionId: row['region_id'].toString(),
      unlockedAt: _dateFromRow(row['unlocked_at']),
      visitCount: _intFromRow(row['visit_count']),
    );
  }

  RegionProgress toModel() {
    return RegionProgress(
      regionId: regionId,
      unlockedAt: unlockedAt,
      visitCount: visitCount,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'region_id': regionId,
      'unlocked_at': unlockedAt.toUtc().toIso8601String(),
      'visit_count': visitCount,
    };
  }
}

class SyncUserProfile {
  const SyncUserProfile({
    required this.name,
    required this.passportId,
    required this.level,
    required this.tier,
    required this.stampCount,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  final String name;
  final String passportId;
  final int level;
  final String tier;
  final int stampCount;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  factory SyncUserProfile.fromModel(UserProfile profile) {
    return SyncUserProfile(
      name: profile.name,
      passportId: profile.passportId,
      level: profile.level,
      tier: profile.tier,
      stampCount: profile.stampCount,
      email: profile.email,
      displayName: profile.displayName,
      photoUrl: profile.photoUrl,
    );
  }

  factory SyncUserProfile.fromRow(Map<String, dynamic> row) {
    return SyncUserProfile(
      name: row['name']?.toString() ?? UserProfile.initial().name,
      passportId:
          row['passport_id']?.toString() ?? UserProfile.initial().passportId,
      level: _intFromRow(row['level']),
      tier: row['tier']?.toString() ?? UserProfile.initial().tier,
      stampCount: _intFromRow(row['stamp_count']),
      email: row['email'] as String?,
      displayName: row['display_name'] as String?,
      photoUrl: row['photo_url'] as String?,
    );
  }

  UserProfile toModel() {
    return UserProfile(
      name: name,
      passportId: passportId,
      level: level == 0 ? 1 : level,
      tier: tier,
      stampCount: stampCount,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      authProvider: AuthProviderType.supabaseGoogle,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'name': name,
      'passport_id': passportId,
      'level': level,
      'tier': tier,
      'stamp_count': stampCount,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
    };
  }
}
