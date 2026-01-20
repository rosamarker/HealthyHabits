import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

// View model for Movesense BLE scanning and connecting
class MovesenseViewModel extends ChangeNotifier {
  // BLE client used for scanning and connecting
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // Stores discovered devices from the current scan
  final List<DiscoveredDevice> _devices = [];
  // Read only list for the UI
  List<DiscoveredDevice> get devices => List.unmodifiable(_devices);

  // Stores the id of the connected device
  String? _connectedDeviceId;
  // True when a device is connected
  bool get isConnected => _connectedDeviceId != null;

  // Stores the connected device details from the scan list
  DiscoveredDevice? _connectedDevice;

  // Returns connected device id
  String? get deviceId => _connectedDeviceId;

  // Returns connected device name or null if empty
  String? get deviceName {
    // Read name from cached device
    final name = _connectedDevice?.name;
    // Treat empty name as missing
    return (name == null || name.trim().isEmpty) ? null : name;
  }

  // Holds the active scan stream
  StreamSubscription? _scanSub;
  // Holds the active connection stream
  StreamSubscription? _connSub;

  // Starts scanning for Movesense devices
  void startScan() {
    // Clear old results
    _devices.clear();
    // Update the UI
    notifyListeners();

    // Stop any previous scan
    _scanSub?.cancel();
    // Start a new scan
    _scanSub = _ble.scanForDevices(
      // No service filter
      withServices: const [],
      // Faster discovery
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      // Keep only Movesense devices
      if (device.name.toLowerCase().contains('movesense')) {
        // Avoid duplicates by id
        if (_devices.every((d) => d.id != device.id)) {
          // Add to list
          _devices.add(device);
          // Update the UI
          notifyListeners();
        }
      }
    });
  }

  // Connects to a device and listens for state changes
  Future<void> connect(String deviceId) async {
    // Stop any previous connection stream
    _connSub?.cancel();
    // Connect and listen for updates
    _connSub = _ble.connectToDevice(id: deviceId).listen((update) {
      // Handle connected state
      if (update.connectionState == DeviceConnectionState.connected) {
        // Save connected id
        _connectedDeviceId = deviceId;
        // Reset cached device
        _connectedDevice = null;
        // Find device details from scan list
        for (final d in _devices) {
          // Match by id
          if (d.id == deviceId) {
            // Cache the device
            _connectedDevice = d;
            // Stop searching
            break;
          }
        }
        // Update the UI
        notifyListeners();
      }
      // Handle disconnected state
      if (update.connectionState == DeviceConnectionState.disconnected) {
        // Clear connected id
        _connectedDeviceId = null;
        // Clear cached device
        _connectedDevice = null;
        // Update the UI
        notifyListeners();
      }
    });
  }

  // Disconnects by cancelling the connection stream
  Future<void> disconnect() async {
    // Stop connection updates
    await _connSub?.cancel();
    // Clear connected id
    _connectedDeviceId = null;
    // Clear cached device
    _connectedDevice = null;
    // Update the UI
    notifyListeners();
  }

  @override
  // Cleanup subscriptions when the view model is destroyed
  void dispose() {
    // Stop scanning
    _scanSub?.cancel();
    // Stop connection updates
    _connSub?.cancel();
    // Run base cleanup
    super.dispose();
  }
}