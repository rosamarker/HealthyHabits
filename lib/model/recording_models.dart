// lib/model/recording_models.dart
import 'dart:convert';

class SensorSample {
  final int tsMs; // epoch millis
  final int? heartRate;
  final int? batteryPercent;

  const SensorSample({
    required this.tsMs,
    this.heartRate,
    this.batteryPercent,
  });

  Map<String, dynamic> toMap() => {
        'tsMs': tsMs,
        'heartRate': heartRate,
        'batteryPercent': batteryPercent,
      };

  factory SensorSample.fromMap(Map<String, dynamic> map) => SensorSample(
        tsMs: (map['tsMs'] ?? 0) as int,
        heartRate: map['heartRate'] as int?,
        batteryPercent: map['batteryPercent'] as int?,
      );

  String toJson() => jsonEncode(toMap());
  factory SensorSample.fromJson(String s) =>
      SensorSample.fromMap(jsonDecode(s) as Map<String, dynamic>);
}

class RecordingSessionMeta {
  final String sessionId;
  final String? clientId;

  final String? deviceId;
  final String? deviceName;

  final int startedAtMs;
  final int? endedAtMs;

  const RecordingSessionMeta({
    required this.sessionId,
    required this.startedAtMs,
    this.endedAtMs,
    this.clientId,
    this.deviceId,
    this.deviceName,
  });

  RecordingSessionMeta copyWith({
    String? sessionId,
    String? clientId,
    String? deviceId,
    String? deviceName,
    int? startedAtMs,
    int? endedAtMs,
  }) {
    return RecordingSessionMeta(
      sessionId: sessionId ?? this.sessionId,
      clientId: clientId ?? this.clientId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      startedAtMs: startedAtMs ?? this.startedAtMs,
      endedAtMs: endedAtMs ?? this.endedAtMs,
    );
  }

  Map<String, dynamic> toMap() => {
        'sessionId': sessionId,
        'clientId': clientId,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'startedAtMs': startedAtMs,
        'endedAtMs': endedAtMs,
      };

  factory RecordingSessionMeta.fromMap(Map<String, dynamic> map) =>
      RecordingSessionMeta(
        sessionId: (map['sessionId'] ?? '') as String,
        clientId: map['clientId'] as String?,
        deviceId: map['deviceId'] as String?,
        deviceName: map['deviceName'] as String?,
        startedAtMs: (map['startedAtMs'] ?? 0) as int,
        endedAtMs: map['endedAtMs'] as int?,
      );

  String toJson() => jsonEncode(toMap());
  factory RecordingSessionMeta.fromJson(String s) =>
      RecordingSessionMeta.fromMap(jsonDecode(s) as Map<String, dynamic>);
}