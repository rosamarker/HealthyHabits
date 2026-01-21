// lib/services/file_recording_repository.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../model/recording_models.dart';
import 'recording_repository.dart';

class FileRecordingRepository implements RecordingRepository {
  // No extra deps: store under systemTemp. Replace with app docs later if desired.
  Directory get _rootDir {
    final dir = Directory('${Directory.systemTemp.path}/healthyhabits_recordings');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  File _sessionFile(String sessionId) => File('${_rootDir.path}/$sessionId.jsonl');
  File get _indexFile => File('${_rootDir.path}/index.json');

  String _newSessionId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    return 'sess_$ts';
  }

  Future<List<RecordingSessionMeta>> _readIndex() async {
    if (!await _indexFile.exists()) return [];
    final s = await _indexFile.readAsString();
    if (s.trim().isEmpty) return [];
    final list = (jsonDecode(s) as List<dynamic>)
        .map((e) => RecordingSessionMeta.fromMap(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<void> _writeIndex(List<RecordingSessionMeta> metas) async {
    final data = metas.map((m) => m.toMap()).toList();
    await _indexFile.writeAsString(jsonEncode(data));
  }

  @override
  Future<RecordingSessionMeta> createSession({
    String? clientId,
    String? deviceId,
    String? deviceName,
  }) async {
    final sessionId = _newSessionId();
    final meta = RecordingSessionMeta(
      sessionId: sessionId,
      clientId: clientId,
      deviceId: deviceId,
      deviceName: deviceName,
      startedAtMs: DateTime.now().millisecondsSinceEpoch,
      endedAtMs: null,
    );

    final f = _sessionFile(sessionId);
    // First line is meta header: {"type":"meta", ...}
    await f.writeAsString('${jsonEncode({'type': 'meta', ...meta.toMap()})}\n');

    final metas = await _readIndex();
    metas.insert(0, meta);
    await _writeIndex(metas);

    return meta;
  }

  @override
  Future<void> appendSample(String sessionId, SensorSample sample) async {
    final f = _sessionFile(sessionId);
    if (!await f.exists()) return;

    // One JSON per line: {"type":"sample", ...}
    await f.writeAsString(
      '${jsonEncode({'type': 'sample', ...sample.toMap()})}\n',
      mode: FileMode.append,
      flush: false,
    );
  }

  @override
  Future<void> closeSession(String sessionId) async {
    final metas = await _readIndex();
    final idx = metas.indexWhere((m) => m.sessionId == sessionId);
    if (idx >= 0) {
      final updated = metas[idx].copyWith(
        endedAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      metas[idx] = updated;
      await _writeIndex(metas);
    }

    final f = _sessionFile(sessionId);
    if (await f.exists()) {
      await f.writeAsString(
        '${jsonEncode({'type': 'end', 'endedAtMs': DateTime.now().millisecondsSinceEpoch})}\n',
        mode: FileMode.append,
        flush: true,
      );
    }
  }

  @override
  Future<List<RecordingSessionMeta>> listSessions() => _readIndex();

  @override
  Stream<SensorSample> streamSamples(String sessionId) async* {
    final f = _sessionFile(sessionId);
    if (!await f.exists()) return;

    final lines = f.openRead().transform(utf8.decoder).transform(const LineSplitter());
    await for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final obj = jsonDecode(line) as Map<String, dynamic>;
      final type = obj['type'] as String?;
      if (type == 'sample') {
        yield SensorSample.fromMap(obj);
      }
    }
  }
}