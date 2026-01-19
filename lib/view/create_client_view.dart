// Required for handling async BLE streams and subscriptions
import 'dart:async';

// Core Flutter UI framework
import 'package:flutter/material.dart';

// Bluetooth Low Energy package used for Movesense
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

// Runtime permission handling (Android + iOS)
import 'package:permission_handler/permission_handler.dart';
import '../view_model/movement_view_model.dart' show MovesenseViewModel;

// Domain models (Client, Exercise)
import '../model/clients.dart';

// ViewModel responsible for client creation logic
import '../view_model/create_client_view_model.dart';

// Widget for adding exercises to a client
import '../widgets/create_exercise_widget.dart';

/// Page responsible for both creating and editing a client
class CreateClientPage extends StatefulWidget {
  // Callback invoked when a client is saved
  final void Function(Client) onCreate;

  // Optional client used when editing an existing entry
  final Client? initialClient;

  const CreateClientPage({
    super.key,
    required this.onCreate,
    this.initialClient,
  });

  @override
  State<CreateClientPage> createState() => _CreateClientPageState();
}

class _CreateClientPageState extends State<CreateClientPage> {
  // Form key used for validation
  final _formKey = GlobalKey<FormState>();

  // ViewModel holding all mutable client data
  final CreateClientViewModel viewModel = CreateClientViewModel();

  // BLE ViewModel dedicated to Movesense handling
  final MovesenseViewModel movesenseVM = MovesenseViewModel();

  // Controllers for text-based inputs
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _motivationController = TextEditingController();

  // Determines whether this page is in edit mode
  bool get isEditMode => widget.initialClient != null;

  @override
  void initState() {
    super.initState();

    // If editing an existing client, populate the form fields
    final c = widget.initialClient;
    if (c != null) {
      // Pre-fill visible text fields
      _nameController.text = c.name;
      _ageController.text = c.age.toString();
      _motivationController.text = c.motivation;

      // Sync non-text fields into the ViewModel
      viewModel.name = c.name;
      viewModel.age = c.age;
      viewModel.gender = c.gender;
      viewModel.active = c.active;

      // Convert stored UNIX timestamp to local DateTime
      viewModel.nextAppointment =
          DateTime.fromMillisecondsSinceEpoch(c.nextAppointment * 1000).toLocal();

      // Preserve previously assigned exercises
      viewModel.exercises.addAll(c.exercises);

      // Preserve existing Movesense association
      viewModel.movesenseDeviceId = c.movesenseDeviceId;
      viewModel.movesenseDeviceName = c.movesenseDeviceName;
    }
  }

  @override
  void dispose() {
    // Clean up controllers to avoid memory leaks
    _nameController.dispose();
    _ageController.dispose();
    _motivationController.dispose();

    // Stop BLE scans and connections
    movesenseVM.dispose();
    super.dispose();
  }

  // Synchronizes text fields into the ViewModel
  void _updateViewModelFromControllers() {
    viewModel.name = _nameController.text;
    viewModel.age = int.tryParse(_ageController.text);
    viewModel.motivation = _motivationController.text;
  }

  // Builds the final Client object before returning it
  Client _buildClientResult() {
    // If a Movesense device is currently connected, persist it
    viewModel.movesenseDeviceId ??= movesenseVM.deviceId;
    viewModel.movesenseDeviceName ??= movesenseVM.deviceName;

    // Create client using ViewModel logic
    final created = viewModel.createClient();

    // If editing, preserve the original client ID
    final originalId = widget.initialClient?.clientId;
    if (originalId != null) {
      return created.copyWith(clientId: originalId);
    }

    return created;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dynamic title depending on mode
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Client' : 'Create Client'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ===== Name =====
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (_) {
                  _updateViewModelFromControllers();
                  return viewModel.validateName();
                },
              ),

              const SizedBox(height: 12),

              // ===== Age =====
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (_) {
                  _updateViewModelFromControllers();
                  return viewModel.validateAge();
                },
              ),

              const SizedBox(height: 12),

              // ===== Gender =====
              DropdownButtonFormField<String>(
                initialValue: viewModel.gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => viewModel.gender = v);
                },
              ),

              const SizedBox(height: 12),

              // ===== Status (Green / Yellow / Red) =====
              DropdownButtonFormField<int>(
                initialValue: viewModel.active,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Active (Green)')),
                  DropdownMenuItem(value: 1, child: Text('Caution (Yellow)')),
                  DropdownMenuItem(value: 2, child: Text('Inactive (Red)')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => viewModel.active = v);
                },
              ),

              const SizedBox(height: 12),

              // ===== Next Appointment (Calendar) =====
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  viewModel.nextAppointment == null
                      ? 'Select Next Appointment'
                      : 'Next: ${viewModel.nextAppointment!.toLocal()}'
                          .split(' ')[0],
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: viewModel.nextAppointment ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => viewModel.nextAppointment = picked);
                  }
                },
              ),

              const SizedBox(height: 12),

              // ===== Motivation =====
              TextFormField(
                controller: _motivationController,
                decoration: const InputDecoration(
                  labelText: 'Motivation',
                  hintText: 'Optional motivation notes',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // ===== Movesense Bluetooth Section =====
              MovesenseConnectWidget(vm: movesenseVM),

              const SizedBox(height: 16),

              // ===== Exercise Creation =====
              ExerciseFormWidget(
                onCreate: (exercise) {
                  setState(() => viewModel.exercises.add(exercise));
                },
              ),

              const SizedBox(height: 12),

              // ===== Submit Button =====
              ElevatedButton(
                onPressed: () {
                  _updateViewModelFromControllers();

                  // Persist Movesense if connected during this session
                  if (movesenseVM.deviceId != null) {
                    viewModel.movesenseDeviceId = movesenseVM.deviceId;
                    viewModel.movesenseDeviceName = movesenseVM.deviceName;
                  }

                  // Validate and return the client
                  if (_formKey.currentState!.validate() && viewModel.validateAll()) {
                    final client = _buildClientResult();
                    widget.onCreate(client);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fix the errors in the form')),
                    );
                  }
                },
                child: Text(isEditMode ? 'Save Changes' : 'Create Client'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget that handles Movesense device scanning and connection
class MovesenseConnectWidget extends StatefulWidget {
  final MovesenseViewModel vm;

  const MovesenseConnectWidget({super.key, required this.vm});

  @override
  State<MovesenseConnectWidget> createState() => _MovesenseConnectWidgetState();
}

class _MovesenseConnectWidgetState extends State<MovesenseConnectWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Movesense Device',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: widget.vm,
              builder: (_, __) {
                final connectedLabel = widget.vm.deviceName ?? widget.vm.deviceId;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.vm.isConnected && connectedLabel != null
                          ? 'Connected: $connectedLabel'
                          : 'No device connected',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              // On iOS this typically resolves to "granted"; on Android it is mandatory.
                              await _requestBlePermissionsIfNeeded(context);
                              widget.vm.startScan();
                            },
                            child: const Text('Scan for devices'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (widget.vm.isConnected)
                          OutlinedButton(
                            onPressed: () async {
                              await widget.vm.disconnect();
                            },
                            child: const Text('Disconnect'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!widget.vm.isConnected)
                      _DeviceList(
                        devices: widget.vm.devices,
                        onConnect: (id) async {
                          await widget.vm.connect(id);
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _requestBlePermissionsIfNeeded(BuildContext context) async {
  // iOS: Bluetooth permission is governed by Info.plist usage strings.
  // Android: runtime permissions required on modern versions.
  try {
    final perms = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];
    final statuses = await perms.request();

    final denied = statuses.values.any(
      (s) => s.isDenied || s.isPermanentlyDenied || s.isRestricted,
    );
    if (denied && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth permissions are required to scan.')),
      );
    }
  } catch (_) {
    // If a permission is not supported on the current platform, ignore.
  }
}

class _DeviceList extends StatelessWidget {
  final List<DiscoveredDevice> devices;
  final Future<void> Function(String deviceId) onConnect;

  const _DeviceList({
    required this.devices,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return const Text('No Movesense devices discovered yet.');
    }

    return Column(
      children: devices
          .map(
            (d) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bluetooth),
              title: Text(d.name.isNotEmpty ? d.name : 'Movesense'),
              subtitle: Text(d.id),
              trailing: TextButton(
                onPressed: () => onConnect(d.id),
                child: const Text('Connect'),
              ),
            ),
          )
          .toList(),
    );
  }
}