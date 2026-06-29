import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/fog_repository.dart';
import '../data/sync_payload.dart';
import '../models/auth_account.dart';
import '../providers/collection_provider.dart';
import '../providers/fog_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/walk_session_provider.dart';

class SyncSnapshot {
  const SyncSnapshot({
    required this.visitedCells,
    required this.walkSessions,
    required this.regionProgress,
    required this.profile,
  });

  final List<SyncVisitedCell> visitedCells;
  final List<SyncWalkSession> walkSessions;
  final List<SyncRegionProgress> regionProgress;
  final SyncUserProfile? profile;

  factory SyncSnapshot.local({
    required FogRepository fogRepository,
    required WalkSessionProvider walk,
    required CollectionProvider collection,
    required ProfileProvider profile,
  }) {
    return SyncSnapshot(
      visitedCells: fogRepository
          .loadAllWithTimestamps()
          .entries
          .map((entry) {
            return SyncVisitedCell(
              cell: entry.key,
              visitedAtMillis: entry.value,
            );
          })
          .toList(growable: false),
      walkSessions: walk.sessions
          .map(SyncWalkSession.fromModel)
          .toList(growable: false),
      regionProgress: collection.progressRecords
          .map(SyncRegionProgress.fromModel)
          .toList(growable: false),
      profile: SyncUserProfile.fromModel(profile.profile),
    );
  }
}

class CloudSyncResult {
  const CloudSyncResult({
    required this.remoteVisitedCellsMerged,
    required this.remoteWalkSessionsMerged,
    required this.remoteRegionProgressMerged,
  });

  final int remoteVisitedCellsMerged;
  final int remoteWalkSessionsMerged;
  final int remoteRegionProgressMerged;
}

class SupabaseSyncGateway {
  SupabaseSyncGateway({required SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  bool get configured => _client?.auth.currentUser != null;

  String? get _userId => _client?.auth.currentUser?.id;

  Future<SyncSnapshot> pull() async {
    final client = _requireClient();

    final visitedRows = await client
        .from('visited_cells')
        .select('cell_x, cell_y, visited_at');
    final sessionRows = await client
        .from('walk_sessions')
        .select(
          'id, started_at, ended_at, distance_km, cleared_km2, '
          'new_cells_count, region_ids',
        )
        .order('started_at', ascending: false);
    final progressRows = await client
        .from('region_progress')
        .select('region_id, unlocked_at, visit_count');
    final profileRows = await client
        .from('user_profiles')
        .select(
          'name, passport_id, level, tier, stamp_count, email, '
          'display_name, photo_url',
        )
        .limit(1);

    return SyncSnapshot(
      visitedCells: _rows(
        visitedRows,
      ).map(SyncVisitedCell.fromRow).toList(growable: false),
      walkSessions: _rows(
        sessionRows,
      ).map(SyncWalkSession.fromRow).toList(growable: false),
      regionProgress: _rows(
        progressRows,
      ).map(SyncRegionProgress.fromRow).toList(growable: false),
      profile: _rows(profileRows).isEmpty
          ? null
          : SyncUserProfile.fromRow(_rows(profileRows).first),
    );
  }

  Future<void> push(SyncSnapshot snapshot) async {
    final client = _requireClient();
    final userId = _userId;
    if (userId == null) return;

    final profile = snapshot.profile;
    if (profile != null) {
      await client.from('user_profiles').upsert([
        {
          ...profile.toRow(),
          'user_id': userId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
      ], onConflict: 'user_id');
    }

    await _upsertMany(
      client,
      'visited_cells',
      snapshot.visitedCells
          .map((cell) {
            return {
              ...cell.toRow(),
              'user_id': userId,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            };
          })
          .toList(growable: false),
      'user_id,cell_x,cell_y',
    );

    await _upsertMany(
      client,
      'walk_sessions',
      snapshot.walkSessions
          .map((session) {
            return {
              ...session.toRow(),
              'user_id': userId,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            };
          })
          .toList(growable: false),
      'user_id,id',
    );

    await _upsertMany(
      client,
      'region_progress',
      snapshot.regionProgress
          .map((progress) {
            return {
              ...progress.toRow(),
              'user_id': userId,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            };
          })
          .toList(growable: false),
      'user_id,region_id',
    );
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      throw StateError('Supabase login is required for cloud sync.');
    }
    return client;
  }

  Future<void> _upsertMany(
    SupabaseClient client,
    String table,
    List<Map<String, dynamic>> rows,
    String onConflict,
  ) async {
    if (rows.isEmpty) return;
    for (final chunk in _chunks(rows, 500)) {
      await client.from(table).upsert(chunk, onConflict: onConflict);
    }
  }

  List<Map<String, dynamic>> _rows(Object value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList(growable: false);
  }

  Iterable<List<T>> _chunks<T>(List<T> items, int size) sync* {
    for (var start = 0; start < items.length; start += size) {
      final end = start + size > items.length ? items.length : start + size;
      yield items.sublist(start, end);
    }
  }
}

class AppSyncCoordinator {
  AppSyncCoordinator({
    required this.remote,
    required this.fogRepository,
    required this.fog,
    required this.walk,
    required this.collection,
    required this.profile,
  });

  final SupabaseSyncGateway remote;
  final FogRepository fogRepository;
  final FogProvider fog;
  final WalkSessionProvider walk;
  final CollectionProvider collection;
  final ProfileProvider profile;

  Future<CloudSyncResult> sync(AuthAccount account) async {
    if (!remote.configured) {
      return const CloudSyncResult(
        remoteVisitedCellsMerged: 0,
        remoteWalkSessionsMerged: 0,
        remoteRegionProgressMerged: 0,
      );
    }

    final pulled = await remote.pull();
    final mergedCells = await fogRepository.mergeVisitedCells({
      for (final cell in pulled.visitedCells) cell.cell: cell.visitedAtMillis,
    });
    fog.loadInitial(fogRepository.loadAll());

    final mergedSessions = await walk.mergeSessions(
      pulled.walkSessions.map((session) => session.toModel()),
    );
    final mergedProgress = await collection.mergeProgress(
      pulled.regionProgress.map((progress) => progress.toModel()),
    );
    final remoteProfile = pulled.profile;
    if (remoteProfile != null) {
      profile.mergeRemoteProfile(remoteProfile.toModel(), account);
    }
    profile.syncProgress(stampCount: collection.unlockedCount);
    profile.syncAccount(account);

    await remote.push(
      SyncSnapshot.local(
        fogRepository: fogRepository,
        walk: walk,
        collection: collection,
        profile: profile,
      ),
    );

    return CloudSyncResult(
      remoteVisitedCellsMerged: mergedCells,
      remoteWalkSessionsMerged: mergedSessions,
      remoteRegionProgressMerged: mergedProgress,
    );
  }
}
