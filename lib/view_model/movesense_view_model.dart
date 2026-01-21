// lib/view_model/movesense_view_model.dart
import 'dart:async';
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

  String? _deviceId;
  String? _deviceName;

  int? _batteryPercent;
  int? _heartRate;

  bool get isScanning => _isScanning;
  bool get isStreaming => _isStreaming;

  MovesenseConnectionState get connectionState => _connState;
  bool get isConnecting => _connState == MovesenseConnectionState.connecting;
  bool get isConnected => _connState == MovesenseConnectionState.connected;

  List<DiscoveredDevice> get foundDevices => List.unmodifiable(_found);

  String? get deviceId => _deviceId;
  String? get deviceName => _deviceName;

  int? get batteryPercent => _batteryPercent;
  int? get heartRate => _heartRate;

  // Standard BLE UUIDs
  static final Uuid _hrService =
      Uuid.parse('0000180d-0000-1000-8000-00805f9b34fb');
  static final Uuid _hrChar =
      Uuid.parse('00002a37-0000-1000-8000-00805f9b34fb');

  static final Uuid _batteryService =
      Uuid.parse('0000180f-0000-1000-8000-00805f9b34fb');
  static final Uuid _batteryChar =
      Uuid.parse('00002a19-0000-1000-8000-00805f9b34fb');

  // Filter: only show devices whose *name* looks like Movesense.
  // Adjust these if your device advertises a different name.
  bool _looksLikeMovesense(String name) {
    final n = name.trim().toLowerCase();
    if (n.isEmpty) return false;

    // Common Movesense patterns
    if (n.startsWith('movesense')) return true;
    if (n.startsWith('mds')) return true;
    if (n.contains('movesense')) return true;

    return false;
  }

  Future<bool> _ensurePermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    }
    return true;
  }

  Future<void> startScan() async {
    final ok = await _ensurePermissions();
    if (!ok) return;

    await stopScan();

    _found.clear();
    _isScanning = true;
    notifyListeners();

    // NOTE: we scan all services but filter by name to avoid Mac/iPhone/etc.
    _scanSub = _ble
        .scanForDevices(withServices: const [], scanMode: ScanMode.lowLatency)
        .listen((d) {
      final name = d.name.trim();
      if (!_looksLikeMovesense(name)) return;

      final idx = _found.indexWhere((x) => x.id == d.id);
      if (idx >= 0) {
        _found[idx] = d;
      } else {
        _found.add(d);
      }
      notifyListeners();
    }, onError: (_) {
      _isScanning = false;
      notifyListeners();
    });
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
    _deviceName = device.name;

    _connState = MovesenseConnectionState.connecting;
    notifyListeners();

    _connSub = _ble
        .connectToDevice(
          id: device.id,
          connectionTimeout: const Duration(seconds: 15),
        )
        .listen((update) async {
      if (update.connectionState == DeviceConnectionState.connected) {
        _connState = MovesenseConnectionState.connected;
        await _readBatteryOnce();
        notifyListeners();
      }

      if (update.connectionState == DeviceConnectionState.disconnected) {
        await _hrSub?.cancel();
        _hrSub = null;

        _isStreaming = false;
        _heartRate = null;

        _batteryPercent = null;

        _deviceId = null;
        _deviceName = null;

        _connState = MovesenseConnectionState.disconnected;
        notifyListeners();
      }
    }, onError: (_) async {
      await disconnect();
    });
  }

  Future<void> disconnect() async {
    await _hrSub?.cancel();
    _hrSub = null;

    _isStreaming = false;
    _heartRate = null;

    await _connSub?.cancel();
    _connSub = null;

    _batteryPercent = null;

    _deviceId = null;
    _deviceName = null;

    _connState = MovesenseConnectionState.disconnected;

    notifyListeners();
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
      // Not all Movesense firmwares expose standard battery service.
    }
  }

  Future<void> startHeartRate() async {
    if (_deviceId == null) return;

    await stopHeartRate();

    final qc = QualifiedCharacteristic(
      deviceId: _deviceId!,
      serviceId: _hrService,
      characteristicId: _hrChar,
    );

    _isStreaming = true;
    notifyListeners();

    _hrSub = _ble.subscribeToCharacteristic(qc).listen((data) {
      final hr = _parseHeartRate(data);
      if (hr != null) {
        _heartRate = hr;
        notifyListeners();
      }
    }, onError: (_) {
      _isStreaming = false;
      notifyListeners();
    });
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
    super.dispose();
  }
}