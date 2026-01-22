// lib/view_model/movesense_view_model.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

enum MovesenseConnectionState { disconnected, connecting, connected }

class MovesenseViewModel extends ChangeNotifier {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _hrSub;

  final List<DiscoveredDevice> _found = [];

  bool _isScanning = false;
  bool _isStreaming = false;

  MovesenseConnectionState _connState = MovesenseConnectionState.disconnected;

  final StreamController<MovesenseConnectionState> _connStateCtrl =
      StreamController<MovesenseConnectionState>.broadcast();

  String? _deviceId;
  String? _deviceName;

  int? _batteryPercent;
  int? _heartRate;

  int? _lastHrUpdateAtMs;

  // --- Public getters ---
  bool get isScanning => _isScanning;
  bool get isStreaming => _isStreaming;

  MovesenseConnectionState get connectionState => _connState;

  /// Used by RecordingService to auto-stop when disconnected.
  Stream<MovesenseConnectionState> get connectionStateStream => _connStateCtrl.stream;

  bool get isConnecting => _connState == MovesenseConnectionState.connecting;
  bool get isConnected => _connState == MovesenseConnectionState.connected;

  List<DiscoveredDevice> get foundDevices => List.unmodifiable(_found);

  String? get deviceId => _deviceId;
  String? get deviceName => _deviceName;

  int? get batteryPercent => _batteryPercent;
  int? get heartRate => _heartRate;

  /// Helpful for debugging “stuck HR”.
  int? get lastHrUpdateAtMs => _lastHrUpdateAtMs;

  // Standard BLE UUIDs (Movesense *may* expose standard HR service when in HR mode)
  static final Uuid _hrService =
      Uuid.parse('0000180d-0000-1000-8000-00805f9b34fb');
  static final Uuid _hrChar =
      Uuid.parse('00002a37-0000-1000-8000-00805f9b34fb');

  static final Uuid _batteryService =
      Uuid.parse('0000180f-0000-1000-8000-00805f9b34fb');
  static final Uuid _batteryChar =
      Uuid.parse('00002a19-0000-1000-8000-00805f9b34fb');

  // Filter: only show devices whose name looks like Movesense.
  bool _looksLikeMovesense(String name) {
    final n = name.trim().toLowerCase();
    if (n.isEmpty) return false;

    // Common Movesense patterns
    if (n.startsWith('movesense')) return true;
    if (n.startsWith('mds')) return true;
    if (n.contains('movesense')) return true;

    return false;
  }

  void _setConnState(MovesenseConnectionState s) {
    if (_connState == s) return;
    _connState = s;
    _connStateCtrl.add(s);
    notifyListeners();
  }

  Future<bool> _ensurePermissions() async {
    // iOS: permission_handler BLE permissions are typically not required at runtime.
    if (!Platform.isAndroid) return true;

    // Android 12+ requires these; older Android often needs location for scan visibility.
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    final location = await Permission.locationWhenInUse.request();

    // Accept either:
    // - scan+connect granted (Android 12+)
    // - location granted (older Android / OEM quirks)
    final ok = (scan.isGranted && connect.isGranted) || location.isGranted;
    return ok;
  }

  Future<void> startScan() async {
    final ok = await _ensurePermissions();
    if (!ok) return;

    await stopScan();

    _found.clear();
    _isScanning = true;
    notifyListeners();

    // Scan broadly but filter hard by name to avoid Apple devices.
    _scanSub = _ble
        .scanForDevices(withServices: const [], scanMode: ScanMode.lowLatency)
        .listen(
      (d) {
        final name = d.name.trim();

        // HARD FILTER (name-only)
        if (!_looksLikeMovesense(name)) return;

        final idx = _found.indexWhere((x) => x.id == d.id);
        if (idx >= 0) {
          _found[idx] = d;
        } else {
          _found.add(d);
        }

        // Optional: sort stable by name (keeps list nice)
        _found.sort((a, b) => (a.name).compareTo(b.name));

        notifyListeners();
      },
      onError: (_) {
        _isScanning = false;
        notifyListeners();
      },
    );
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;

    if (_isScanning) {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> connect(DiscoveredDevice device) async {
    await stopScan();
    await disconnect();

    _deviceId = device.id;
    _deviceName = device.name.trim().isEmpty ? null : device.name.trim();

    _batteryPercent = null;
    _heartRate = null;
    _lastHrUpdateAtMs = null;

    _setConnState(MovesenseConnectionState.connecting);

    _connSub = _ble
        .connectToDevice(
          id: device.id,
          connectionTimeout: const Duration(seconds: 15),
        )
        .listen(
      (update) async {
        if (update.connectionState == DeviceConnectionState.connected) {
          _setConnState(MovesenseConnectionState.connected);
          await _readBatteryOnce();
          notifyListeners();
          return;
        }

        if (update.connectionState == DeviceConnectionState.disconnected) {
          await _cleanupOnDisconnect();
          return;
        }
      },
      onError: (_) async {
        await _cleanupOnDisconnect();
      },
    );
  }

  Future<void> disconnect() async {
    await _cleanupOnDisconnect();
  }

  Future<void> _cleanupOnDisconnect() async {
    await stopScan();

    await _hrSub?.cancel();
    _hrSub = null;

    _isStreaming = false;
    _heartRate = null;
    _lastHrUpdateAtMs = null;

    await _connSub?.cancel();
    _connSub = null;

    _batteryPercent = null;

    _deviceId = null;
    _deviceName = null;

    _setConnState(MovesenseConnectionState.disconnected);
  }

  Future<void> _readBatteryOnce() async {
    if (_deviceId == null) return;

    final qc = QualifiedCharacteristic(
      deviceId: _deviceId!,
      serviceId: _batteryService,
      characteristicId: _batteryChar,
    );

    try {
      final value = await _ble.readCharacteristic(qc);
      if (value.isNotEmpty) {
        _batteryPercent = value[0].clamp(0, 100);
      }
    } catch (_) {
      // Not all firmwares expose standard battery service.
    }
  }

  Future<void> startHeartRate() async {
    if (_deviceId == null || !isConnected) return;

    await stopHeartRate();

    // Reset before starting so the UI won’t “stick” on an old number.
    _heartRate = null;
    _lastHrUpdateAtMs = null;

    final qc = QualifiedCharacteristic(
      deviceId: _deviceId!,
      serviceId: _hrService,
      characteristicId: _hrChar,
    );

    _isStreaming = true;
    notifyListeners();

    _hrSub = _ble.subscribeToCharacteristic(qc).listen(
      (data) {
        final hr = _parseHeartRate(data);
        if (hr == null) return;

        _heartRate = hr;
        _lastHrUpdateAtMs = DateTime.now().millisecondsSinceEpoch;
        notifyListeners();
      },
      onError: (_) {
        _isStreaming = false;
        notifyListeners();
      },
    );
  }

  Future<void> stopHeartRate() async {
    await _hrSub?.cancel();
    _hrSub = null;

    if (_isStreaming) {
      _isStreaming = false;
      notifyListeners();
    }
  }

  int? _parseHeartRate(List<int> data) {
    // Heart Rate Measurement characteristic format:
    // byte0 = flags; HR value is uint8 at byte1 OR uint16 at byte1..2 depending on flags.
    if (data.length < 2) return null;

    final flags = data[0];
    final isUint16 = (flags & 0x01) == 0x01;

    if (!isUint16) return data[1];
    if (data.length < 3) return null;

    final lo = data[1];
    final hi = data[2];
    return (hi << 8) | lo;
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _hrSub?.cancel();
    _connStateCtrl.close();
    super.dispose();
  }
}