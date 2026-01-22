// lib/services/sembast_recording_repository.dart
import 'dart:async';

import 'package:sembast/sembast.dart';

import '../model/recording_models.dart';
import 'app_database.dart';
import 'recording_repository.dart';

class SembastRecordingRepository implements RecordingRepository {
  final StoreRef<String, Map<String, Object?>> _sessions =
      stringMapStoreFactory.store('recording_sessions');

  final StoreRef<int, Map<String, Object?>> _samples =
      intMapStoreFactory.store('recording_samples');

  String _newSessionId() => 'sess_${DateTime.now().millisecondsSinceEpoch}';

  @override
  Future<RecordingSessionMeta> createSession({
    String? clientId,
    String? deviceId,
    String? deviceName,
  }) async {
    final db = await AppDatabase.instance();

    final meta = RecordingSessionMeta(
      sessionId: _newSessionId(),
      clientId: clientId,
      deviceId: deviceId,
      deviceName: deviceName,
      startedAtMs: DateTime.now().millisecondsSinceEpoch,
      endedAtMs: null,
    );

    await _sessions.record(meta.sessionId).put(db, meta.toMap());
    return meta;
  }

  @override
  Future<void> appendSample(String sessionId, SensorSample sample) async {
    final db = await AppDatabase.instance();

    // store includes sessionId so we can query samples by session later
    final data = <String, Object?>{
      ...sample.toMap(),
      'sessionId': sessionId,
    };

    await _samples.add(db, data);
  }

  @override
  Future<void> closeSession(String sessionId) async {
    final db = await AppDatabase.instance();

    final existing = await _sessions.record(sessionId).get(db);
    if (existing == null) return;

    final meta = RecordingSessionMeta.fromMap(Map<String, dynamic>.from(existing));
    final updated = meta.copyWith(
      endedAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    await _sessions.record(sessionId).put(db, updated.toMap());
  }

  @override
  Future<List<RecordingSessionMeta>> listSessions() async {
    final db = await AppDatabase.instance();

    final records = await _sessions.find(
      db,
      finder: Finder(sortOrders: [SortOrder('startedAtMs', false)]),
    );

    return records
        .map((r) => RecordingSessionMeta.fromMap(Map<String, dynamic>.from(r.value)))
        .toList();
  }

  @override
  Stream<SensorSample> streamSamples(String sessionId) async* {
    final db = await AppDatabase.instance();

    final finder = Finder(
      filter: Filter.equals('sessionId', sessionId),
      sortOrders: [SortOrder('tsMs')],
    );

    final records = await _samples.find(db, finder: finder);
    for (final r in records) {
      yield SensorSample.fromMap(Map<String, dynamic>.from(r.value));
    }
  }
}