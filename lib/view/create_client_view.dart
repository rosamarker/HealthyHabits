// lib/view/create_client_view.dart
import 'package:flutter/material.dart';

import '../model/clients.dart';
import '../view_model/create_client_view_model.dart';

class CreateClientPage extends StatefulWidget {
  final void Function(Client created) onCreate;
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
  late final CreateClientViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = CreateClientViewModel(initialClient: widget.initialClient);
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickNextAppointment() async {
    final now = DateTime.now();
    final initial = viewModel.nextAppointment ?? now;

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: initial,
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    viewModel.setNextAppointment(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  void _save() {
    final client = viewModel.buildClient(existingClientId: widget.initialClient?.clientId);
    widget.onCreate(client);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (_, __) {
        final appt = viewModel.nextAppointment;
        final apptText = appt == null
            ? 'Not set'
            : '${appt.year}-${appt.month.toString().padLeft(2, '0')}-${appt.day.toString().padLeft(2, '0')} '
              '${appt.hour.toString().padLeft(2, '0')}:${appt.minute.toString().padLeft(2, '0')}';

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.initialClient == null ? 'Create client' : 'Edit client'),
            actions: [
              IconButton(
                onPressed: _save,
                icon: const Icon(Icons.check),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: viewModel.nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: viewModel.ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: viewModel.gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) {
                    if (v != null) viewModel.setGender(v);
                  },
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<int>(
                  value: viewModel.active,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Green')),
                    DropdownMenuItem(value: 1, child: Text('Yellow')),
                    DropdownMenuItem(value: 2, child: Text('Red')),
                  ],
                  onChanged: (v) {
                    if (v != null) viewModel.setActive(v);
                  },
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: viewModel.motivationController,
                  decoration: const InputDecoration(labelText: 'Motivation'),
                  maxLines: 3,
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: Text('Next appointment: $apptText')),
                    TextButton(
                      onPressed: _pickNextAppointment,
                      child: const Text('Pick'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                const Text(
                  'Movesense link',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.bluetooth, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (viewModel.movesenseDeviceName ?? viewModel.movesenseDeviceId) ??
                            'No device linked',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Placeholder for later: you will link this to Movesense UI
                        // For now it keeps build stable
                        viewModel.setMovesenseLink(deviceId: null, deviceName: null);
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                const Text(
                  'Exercises',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (viewModel.exercises.isEmpty)
                  const Text('No exercises yet')
                else
                  ...viewModel.exercises.map(
                    (e) => ListTile(
                      title: Text(e.name),
                      subtitle: Text(e.description),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => viewModel.removeExercise(e.exerciseId),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(widget.initialClient == null ? 'Create' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}