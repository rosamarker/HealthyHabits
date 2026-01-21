// lib/services/recording_repository.dart
import '../model/recording_models.dart';

abstract class RecordingRepository {
  /// Creates a new session file and returns the created meta.
  Future<RecordingSessionMeta> createSession({
    String? clientId,
    String? deviceId,
    String? deviceName,
  });

  /// Appends one sample to the session.
  Future<void> appendSample(String sessionId, SensorSample sample);

  /// Marks session ended (writes footer/meta update).
  Future<void> closeSession(String sessionId);

  /// Returns existing sessions (lightweight index).
  Future<List<RecordingSessionMeta>> listSessions();

  /// Loads samples from a session file (may be large).
  Stream<SensorSample> streamSamples(String sessionId);
}