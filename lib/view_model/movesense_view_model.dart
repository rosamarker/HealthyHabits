// lib/view_model/movesense_view_model.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class MovesenseViewModel extends ChangeNotifier {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _hrSub;

  final List<DiscoveredDevice> _devices = [];
  DiscoveredDevice? _selected;

  bool _isScanning = false;
  bool _isStreaming = false;

  DeviceConnectionState _connectionState = DeviceConnectionState.disconnected;

  int? _heartRate;
  int? _batteryPercent;

  // Standard BLE services/characteristics (Movesense typically supports these)
  static final Uuid _hrService =
      Uuid.parse("0000180d-0000-1000-8000-00805f9b34fb");
  static final Uuid _hrChar =
      Uuid.parse("00002a37-0000-1000-8000-00805f9b34fb");

  static final Uuid _batteryService =
      Uuid.parse("0000180f-0000-1000-8000-00805f9b34fb");
  static final Uuid _batteryChar =
      Uuid.parse("00002a19-0000-1000-8000-00805f9b34fb");

  // -------- Getters used by your widget --------
  bool get isScanning => _isScanning;
  bool get isStreaming => _isStreaming;

  int? get heartRate => _heartRate;
  int? get batteryPercent => _batteryPercent;

  List<DiscoveredDevice> get discoveredDevices => List.unmodifiable(_devices);

  bool get isConnected => _connectionState == DeviceConnectionState.connected;
  DeviceConnectionState get connectionState => _connectionState;

  String? get deviceId => _selected?.id;
  String? get deviceName {
    final n = _selected?.name ?? '';
    if (n.trim().isNotEmpty) return n;
    return _selected?.id;
  }

  // -------- Permissions --------
  Future<void> _ensureBlePermissions() async {
    // Keep it permissive across iOS/Android.
    // On iOS, many of these will be "granted" or ignored depending on OS version.
    final perms = <Permission>[
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];

    for (final p in perms) {
      final status = await p.status;
      if (!status.isGranted) {
        await p.request();
      }
    }
  }

  // -------- Scan --------
  Future<void> startScan({Duration timeout = const Duration(seconds: 6)}) async {
    await _ensureBlePermissions();

    await stopScan();

    _devices.clear();
    _isScanning = true;
    notifyListeners();

    _scanSub = _ble
        .scanForDevices(
          withServices: const [],
          scanMode: ScanMode.lowLatency,
        )
        .listen((d) {
      // Filter: keep Movesense-y devices; adjust if your device advertises differently
      final name = (d.name).toLowerCase();
      final looksLikeMovesense =
          name.contains('movesense') || name.contains('msense');

      if (!looksLikeMovesense) return;

      final already = _devices.any((x) => x.id == d.id);
      if (!already) {
        _devices.add(d);
        notifyListeners();
      }
    }, onError: (_) {
      _isScanning = false;
      notifyListeners();
    });

    // Auto stop after timeout
    Future.delayed(timeout, () async {
      if (_isScanning) {
        await stopScan();
      }
    });
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    _isScanning = false;
    notifyListeners();
  }

  // Convenience: scan + connect to first found device
  Future<void> quickConnect() async {
    if (isConnected) return;

    await startScan(timeout: const Duration(seconds: 6));

    // Give scan a moment to populate results
    await Future.delayed(const Duration(seconds: 2));

    if (_devices.isNotEmpty) {
      await connectToDevice(_devices.first);
    } else {
      // Stop scan if nothing found
      await stopScan();
    }
  }

  // -------- Connect / Disconnect --------
  Future<void> connectToDevice(DiscoveredDevice device) async {
    await _ensureBlePermissions();
    await stopScan();

    _selected = device;
    _connectionState = DeviceConnectionState.connecting;
    notifyListeners();

    await _connSub?.cancel();
    _connSub = _ble
        .connectToDevice(
          id: device.id,
          connectionTimeout: const Duration(seconds: 12),
        )
        .listen((update) async {
      _connectionState = update.connectionState;

      // If we disconnect, stop streaming
      if (_connectionState == DeviceConnectionState.disconnected) {
        _isStreaming = false;
        await _hrSub?.cancel();
        _hrSub = null;
      }

      notifyListeners();

      // Read battery when connected
      if (_connectionState == DeviceConnectionState.connected) {
        await _readBattery();
      }
    }, onError: (_) {
      _connectionState = DeviceConnectionState.disconnected;
      _isStreaming = false;
      notifyListeners();
    });
  }

  Future<void> disconnect() async {
    await stopHeartRate();

    await _connSub?.cancel();
    _connSub = null;

    _connectionState = DeviceConnectionState.disconnected;
    notifyListeners();
  }

  // -------- Battery --------
  Future<void> _readBattery() async {
    if (!isConnected || _selected == null) return;

    final qc = QualifiedCharacteristic(
      deviceId: _selected!.id,
      serviceId: _batteryService,
      characteristicId: _batteryChar,
    );

    try {
      final data = await _ble.readCharacteristic(qc);
      if (data.isNotEmpty) {
        _batteryPercent = data.first;
        notifyListeners();
      }
    } catch (_) {
      // Battery read is optional; ignore failures to keep UX smooth
    }
  }

  // -------- Heart rate streaming --------
  Future<void> startHeartRate() async {
    if (!isConnected || _selected == null) return;
    if (_isStreaming) return;

    final qc = QualifiedCharacteristic(
      deviceId: _selected!.id,
      serviceId: _hrService,
      characteristicId: _hrChar,
    );

    _isStreaming = true;
    notifyListeners();

    await _hrSub?.cancel();
    _hrSub = _ble.subscribeToCharacteristic(qc).listen((data) {
      final hr = _parseHeartRateMeasurement(data);
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

    _isStreaming = false;
    notifyListeners();
  }

  int? _parseHeartRateMeasurement(List<int> data) {
    // BLE Heart Rate Measurement (0x2A37)
    // byte0 = flags; if bit0 set => 16-bit HR, else 8-bit HR
    if (data.length < 2) return null;
    final flags = data[0];
    final is16Bit = (flags & 0x01) != 0;

    if (!is16Bit) {
      return data[1];
    }

    if (data.length < 3) return null;
    return data[1] | (data[2] << 8);
  }

  // -------- Cleanup --------
  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _hrSub?.cancel();
    super.dispose();
  }

  // -------- Fallback "empty" device (if you need it elsewhere) --------
  // Kept here because you previously had an error about DiscoveredDevice(...) params.
  DiscoveredDevice emptyDevice() {
    return DiscoveredDevice(
      id: '',
      name: '',
      serviceUuids: const [],
      rssi: 0,
      manufacturerData: Uint8List(0),
      serviceData: const {},
    );
  }
}