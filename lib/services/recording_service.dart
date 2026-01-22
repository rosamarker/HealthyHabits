// lib/services/recording_service.dart
import 'dart:async';

import '../model/recording_models.dart';
import '../view_model/movesense_view_model.dart';
import 'recording_repository.dart';

class RecordingService {
  final RecordingRepository repo;
  final MovesenseViewModel movesenseVM;

  RecordingSessionMeta? _current;
  Timer? _ticker;

  StreamSubscription<MovesenseConnectionState>? _connSub;
  StreamController<SensorSample>? _liveController;

  RecordingService({
    required this.repo,
    required this.movesenseVM,
  });

  bool get isRecording => _current != null;
  RecordingSessionMeta? get currentSession => _current;

  Stream<SensorSample> get liveSamples {
    _liveController ??= StreamController<SensorSample>.broadcast();
    return _liveController!.stream;
  }

  // Starts a new recording session and writes samples at a fixed cadence (1 Hz)
  Future<RecordingSessionMeta> start({String? clientId}) async {
    if (_current != null) return _current!;

    final meta = await repo.createSession(
      clientId: clientId,
      deviceId: movesenseVM.deviceId,
      deviceName: movesenseVM.deviceName,
    );
    _current = meta;

    _liveController ??= StreamController<SensorSample>.broadcast();

    // Record at a fixed cadence (1 Hz) using latest values from Movesense VM
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      final cur = _current;
      if (cur == null) return;

      final sample = SensorSample(
        tsMs: DateTime.now().millisecondsSinceEpoch,
        heartRate: movesenseVM.heartRate,
        batteryPercent: movesenseVM.batteryPercent,
      );

      _liveController?.add(sample);

      try {
        await repo.appendSample(cur.sessionId, sample);
      } catch (_) {
        // Avoid crashing the timer loop on IO/DB errors.
      }
    });

    // Auto-stop if device disconnects
    // This prevents recording endlessly if the sensor drops
    _connSub = movesenseVM.connectionStateStream.listen((state) async {
      if (_current == null) return;

      final disconnected = (state == MovesenseConnectionState.disconnected);
      if (disconnected) {
        await stop();
      }
    });

    return meta;
  }

  Future<void> stop() async {
    final cur = _current;
    if (cur == null) return;

    _ticker?.cancel();
    _ticker = null;

    await _connSub?.cancel();
    _connSub = null;

    try {
      await repo.closeSession(cur.sessionId);
    } catch (_) {
      // Ignore close errors 
      // session file/db may still be usable
    }

    _current = null;
  }

  void dispose() {
    _ticker?.cancel();
    _connSub?.cancel();
    _liveController?.close();
    _liveController = null;
  }
}