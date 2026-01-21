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

  StreamSubscription? _vmListener;
  StreamController<SensorSample>? _liveController;

  int? _lastHr;
  int? _lastBatt;

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

  Future<RecordingSessionMeta> start({String? clientId}) async {
    if (_current != null) return _current!;

    final meta = await repo.createSession(
      clientId: clientId,
      deviceId: movesenseVM.deviceId,
      deviceName: movesenseVM.deviceName,
    );
    _current = meta;

    _lastHr = movesenseVM.heartRate;
    _lastBatt = movesenseVM.batteryPercent;

    _liveController ??= StreamController<SensorSample>.broadcast();

    // Record at a fixed cadence (e.g., 1 Hz) using latest values from VM.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_current == null) return;

      final sample = SensorSample(
        tsMs: DateTime.now().millisecondsSinceEpoch,
        heartRate: movesenseVM.heartRate,
        batteryPercent: movesenseVM.batteryPercent,
      );

      // Avoid writing pure null/no-change spam if desired:
      final hr = sample.heartRate;
      final b = sample.batteryPercent;
      final changed = (hr != null && hr != _lastHr) || (b != null && b != _lastBatt);
      if (!changed && hr == null && b == null) return;

      _lastHr = hr ?? _lastHr;
      _lastBatt = b ?? _lastBatt;

      _liveController?.add(sample);
      await repo.appendSample(_current!.sessionId, sample);
    });

    // Extra: stop recording automatically if device disconnects.
    _vmListener = movesenseVM.connectionStateStream.listen((state) async {
      if (_current == null) return;
      if (!movesenseVM.isConnected && !movesenseVM.isConnecting) {
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

    await _vmListener?.cancel();
    _vmListener = null;

    await repo.closeSession(cur.sessionId);
    _current = null;
  }

  void dispose() {
    _ticker?.cancel();
    _vmListener?.cancel();
    _liveController?.close();
  }
}