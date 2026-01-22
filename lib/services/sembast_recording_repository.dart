// lib/services/sembast_recording_repository.dart
import 'dart:async';
import 'dart:math';

import 'package:sembast/sembast.dart';

import '../model/recording_models.dart';
import 'app_database.dart';
import 'recording_repository.dart';

class SembastRecordingRepository implements RecordingRepository {
  // Sessions are keyed by sessionId (String)
  final StoreRef<String, Map<String, Object?>> _sessions =
      stringMapStoreFactory.store('recording_sessions');

  // Samples are many-per-session, best as auto-increment int keys
  final StoreRef<int, Map<String, Object?>> _samples =
      intMapStoreFactory.store('recording_samples');

  String _newSessionId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final r = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'sess_${ts}_$r';
  }

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

    final data = <String, Object?>{
      ...sample.toMap(),
      'sessionId': sessionId,
    };

    // Works because _samples is int-key store
    await _samples.add(db, data);
  }

  @override
  Future<void> closeSession(String sessionId) async {
    final db = await AppDatabase.instance();

    final existing = await _sessions.record(sessionId).get(db);
    if (existing == null) return;

    final meta = RecordingSessionMeta.fromMap(existing);
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
      finder: Finder(
        sortOrders: [SortOrder('startedAtMs', false)],
      ),
    );

    return records
        .map((r) => RecordingSessionMeta.fromMap(r.value))
        .toList();
  }

  @override
  Stream<SensorSample> streamSamples(String sessionId) async* {
    final db = await AppDatabase.instance();

    // Filter samples by sessionId, ordered by timestamp
    final finder = Finder(
      filter: Filter.equals('sessionId', sessionId),
      sortOrders: [SortOrder('tsMs', true)],
    );

    final records = await _samples.find(db, finder: finder);

    for (final r in records) {
      yield SensorSample.fromMap(r.value);
    }
  }
}