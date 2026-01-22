// lib/view/create_client_view.dart
import 'package:flutter/material.dart';

import '../model/clients.dart';
import '../view_model/create_client_view_model.dart';

class CreateClientPage extends StatefulWidget {
  // Keep for compatibility, but callers should rely on the returned Client.
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
    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted || time == null) return;

    viewModel.setNextAppointment(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _addExerciseDialog() async {
    // NOTE:
    // Do NOT manually dispose these controllers. Disposing them immediately after
    // Navigator.pop(...) can intermittently trigger the Flutter assertion:
    // '_dependents.isEmpty' is not true (seen on iOS).
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    // Countable fields
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '10');

    // Time-based fields (MINUTES)
    final minutesCtrl = TextEditingController(text: '1');

    bool isCountable = true;

    String? validatePositiveInt(String v, {bool allowZero = true}) {
      final n = int.tryParse(v.trim());
      if (n == null) return 'Enter a valid number';
      if (!allowZero && n <= 0) return 'Must be > 0';
      if (allowZero && n < 0) return 'Must be ≥ 0';
      return null;
    }

    final formKey = GlobalKey<FormState>();

    final added = await showDialog<Exercise>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add exercise'),
          content: StatefulBuilder(
            builder: (ctx2, setState2) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Name required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: isCountable,
                        onChanged: (v) => setState2(() => isCountable = v),
                        title: Text(isCountable ? 'Reps/sets' : 'Stopwatch (minutes)'),
                      ),
                      const SizedBox(height: 8),
                      if (isCountable) ...[
                        TextFormField(
                          controller: setsCtrl,
                          decoration: const InputDecoration(labelText: 'Sets'),
                          keyboardType: TextInputType.number,
                          validator: (v) => validatePositiveInt(v ?? '', allowZero: false),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: repsCtrl,
                          decoration: const InputDecoration(labelText: 'Reps'),
                          keyboardType: TextInputType.number,
                          validator: (v) => validatePositiveInt(v ?? '', allowZero: false),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: minutesCtrl,
                          decoration: const InputDecoration(labelText: 'Minutes'),
                          keyboardType: TextInputType.number,
                          validator: (v) => validatePositiveInt(v ?? '', allowZero: false),
                        ),
                        const SizedBox(height: 6),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'This will create a countdown timer for the client',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;

                final minutes = int.tryParse(minutesCtrl.text.trim()) ?? 0;

                final exercise = Exercise(
                  exerciseId: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  sets: isCountable ? (int.tryParse(setsCtrl.text.trim()) ?? 0) : 0,
                  reps: isCountable ? (int.tryParse(repsCtrl.text.trim()) ?? 0) : 0,
                  // Store as seconds in the model (compatible with your existing timer code)
                  time: isCountable ? 0 : (minutes * 60),
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

    if (!mounted) return;

    if (added != null) {
      viewModel.addExercise(added);
    }
  }

  void _save() {
    final client = viewModel.buildClient(existingClientId: widget.initialClient?.clientId);

    // Keep old callback flow (in case any screen still relies on it)
    widget.onCreate(client);

    // Critical: also RETURN the client so caller can reliably add/update.
    Navigator.pop(context, client);
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
                  initialValue: viewModel.gender,
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
                  initialValue: viewModel.active,
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
                        overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Exercises',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addExerciseDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (viewModel.exercises.isEmpty)
                  const Text('No exercises yet')
                else
                  ...viewModel.exercises.map(
                    (e) {
                      final subtitle = e.isCountable
                          ? '${e.description}\n${e.sets} sets × ${e.reps} reps'
                          : '${e.description}\n${(e.time / 60).round()} min';

                      return ListTile(
                        title: Text(e.name),
                        subtitle: Text(subtitle),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => viewModel.removeExercise(e.exerciseId),
                        ),
                      );
                    },
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