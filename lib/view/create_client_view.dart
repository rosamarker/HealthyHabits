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
    FocusScope.of(context).unfocus();

    final client = viewModel.buildClient(
      existingClientId: widget.initialClient?.clientId,
    );

    widget.onCreate(client);
    Navigator.pop(context, client);
  }

  Future<void> _addExerciseDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '10');
    final timeCtrl = TextEditingController(text: '60');

    bool isCountable = true;

    final created = await showDialog<Exercise>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return AlertDialog(
              title: const Text('Add exercise'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            value: true,
                            groupValue: isCountable,
                            onChanged: (v) => setLocalState(() => isCountable = v ?? true),
                            title: const Text('Sets/Reps'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            value: false,
                            groupValue: isCountable,
                            onChanged: (v) => setLocalState(() => isCountable = v ?? false),
                            title: const Text('Time'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (isCountable) ...[
                      TextField(
                        controller: setsCtrl,
                        decoration: const InputDecoration(labelText: 'Sets'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: repsCtrl,
                        decoration: const InputDecoration(labelText: 'Reps'),
                        keyboardType: TextInputType.number,
                      ),
                    ] else ...[
                      TextField(
                        controller: timeCtrl,
                        decoration: const InputDecoration(labelText: 'Time (seconds)'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exercise name is required.')),
                      );
                      return;
                    }

                    final sets = int.tryParse(setsCtrl.text.trim()) ?? 0;
                    final reps = int.tryParse(repsCtrl.text.trim()) ?? 0;
                    final time = int.tryParse(timeCtrl.text.trim()) ?? 0;

                    final exercise = Exercise(
                      exerciseId: DateTime.now().microsecondsSinceEpoch.toString(),
                      name: name,
                      description: descCtrl.text.trim(),
                      sets: isCountable ? sets : 0,
                      reps: isCountable ? reps : 0,
                      time: isCountable ? 0 : time,
                      isCountable: isCountable,
                    );

                    Navigator.pop(ctx, exercise);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created != null) {
      viewModel.addExercise(created);
    }
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
                        viewModel.setMovesenseLink(deviceId: null, deviceName: null);
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Exercises',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addExerciseDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add exercise'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (viewModel.exercises.isEmpty)
                  const Text('No exercises yet')
                else
                  ...viewModel.exercises.map(
                    (e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.name),
                      subtitle: Text(
                        e.isCountable
                            ? '${e.description}\n${e.sets} sets x ${e.reps} reps'
                            : '${e.description}\n${e.time} sec',
                      ),
                      isThreeLine: true,
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