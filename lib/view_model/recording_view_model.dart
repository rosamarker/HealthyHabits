// lib/view_model/recording_view_model.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../model/recording_models.dart';
import '../services/recording_service.dart';

class RecordingViewModel extends ChangeNotifier {
  final RecordingService service;

  RecordingSessionMeta? _current;
  int _sampleCount = 0;
  DateTime? _startedAt;
  String? _clientId;

  StreamSubscription<SensorSample>? _liveSub;

  RecordingViewModel({required this.service});

  bool get isRecording => _current != null;
  int get sampleCount => _sampleCount;

  Duration get elapsed {
    if (_startedAt == null) return Duration.zero;
    return DateTime.now().difference(_startedAt!);
  }

  RecordingSessionMeta? get currentSession => _current;

  String? get currentClientId => _clientId;

  Future<void> start({String? clientId}) async {
    if (isRecording) return;

    _clientId = clientId;
    _sampleCount = 0;
    _startedAt = DateTime.now();

    _current = await service.start(clientId: clientId);

    _liveSub = service.liveSamples.listen((_) {
      _sampleCount += 1;
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> stop() async {
    if (!isRecording) return;
    await service.stop();

    await _liveSub?.cancel();
    _liveSub = null;

    _current = null;
    _startedAt = null;
    _clientId = null;

    notifyListeners();
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    service.dispose();
    super.dispose();
  }
}