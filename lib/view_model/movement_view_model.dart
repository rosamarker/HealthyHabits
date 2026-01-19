import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class MovesenseViewModel extends ChangeNotifier {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  final List<DiscoveredDevice> _devices = [];
  List<DiscoveredDevice> get devices => List.unmodifiable(_devices);

  String? _connectedDeviceId;
  bool get isConnected => _connectedDeviceId != null;

  DiscoveredDevice? _connectedDevice;

  /// Connected device identifier, if any.
  String? get deviceId => _connectedDeviceId;

  /// Connected device name (may be empty on iOS depending on advertising).
  String? get deviceName {
    final name = _connectedDevice?.name;
    return (name == null || name.trim().isEmpty) ? null : name;
  }

  StreamSubscription? _scanSub;
  StreamSubscription? _connSub;

  void startScan() {
    _devices.clear();
    notifyListeners();

    _scanSub?.cancel();
    _scanSub = _ble.scanForDevices(
      withServices: const [],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      if (device.name.toLowerCase().contains('movesense')) {
        if (_devices.every((d) => d.id != device.id)) {
          _devices.add(device);
          notifyListeners();
        }
      }
    });
  }

  Future<void> connect(String deviceId) async {
    _connSub?.cancel();
    _connSub = _ble.connectToDevice(id: deviceId).listen((update) {
      if (update.connectionState == DeviceConnectionState.connected) {
        _connectedDeviceId = deviceId;
        _connectedDevice = null;
        for (final d in _devices) {
          if (d.id == deviceId) {
            _connectedDevice = d;
            break;
          }
        }
        notifyListeners();
      }
      if (update.connectionState == DeviceConnectionState.disconnected) {
        _connectedDeviceId = null;
        _connectedDevice = null;
        notifyListeners();
      }
    });
  }

  Future<void> disconnect() async {
    await _connSub?.cancel();
    _connectedDeviceId = null;
    _connectedDevice = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}