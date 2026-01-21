// lib/view/create_client_view.dart
import 'package:flutter/material.dart';

import '../model/clients.dart';
import '../view_model/create_client_view_model.dart';

class CreateClientPage extends StatefulWidget {
  /// Kept for compatibility with existing callers.
  /// Callers should still rely on the returned Client from Navigator.pop.
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

  Future<void> _addExercise() async {
    // IMPORTANT:
    // Use a dedicated page instead of a dialog to avoid framework assertion:
    // "_dependents.isEmpty" (can happen when dialogs/snackbars/contexts overlap).
    final ex = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(builder: (_) => const AddExercisePage()),
    );

    if (!mounted) return;
    if (ex != null) {
      viewModel.addExercise(ex);
    }
  }

  void _save() {
    final client =
        viewModel.buildClient(existingClientId: widget.initialClient?.clientId);

    // Keep old callback flow (in case other screens rely on it).
    widget.onCreate(client);

    // Critical: return the client so caller can add/update reliably.
    if (!mounted) return;
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
                tooltip: widget.initialClient == null ? 'Create' : 'Save',
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
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: viewModel.ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                // Note: value deprecation depends on your Flutter channel.
                // If your analyzer complains, switch to initialValue.
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
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => viewModel.setMovesenseLink(deviceId: null, deviceName: null),
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
                      onPressed: _addExercise,
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
                    (e) => ListTile(
                      title: Text(e.name),
                      subtitle: Text(
                        e.isCountable
                            ? '${e.description}\n${e.sets} sets × ${e.reps} reps'
                            : '${e.description}\n${_formatDurationFromSeconds(e.time)}',
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

String _formatDurationFromSeconds(int seconds) {
  final mins = seconds ~/ 60;
  final secs = seconds % 60;
  if (mins <= 0) return '${secs}s';
  if (secs == 0) return '${mins}m';
  return '${mins}m ${secs}s';
}

/// Full-screen exercise editor to avoid dialog/context lifecycle assertions.
/// Supports:
/// - Countable: sets + reps
/// - Time-based: minutes + seconds (stored as Exercise.time in seconds)
class AddExercisePage extends StatefulWidget {
  const AddExercisePage({super.key});

  @override
  State<AddExercisePage> createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final _setsCtrl = TextEditingController(text: '3');
  final _repsCtrl = TextEditingController(text: '10');

  // Minutes-based stopwatch/countdown input
  final _minutesCtrl = TextEditingController(text: '1');
  final _secondsCtrl = TextEditingController(text: '0');

  bool _isCountable = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _minutesCtrl.dispose();
    _secondsCtrl.dispose();
    super.dispose();
  }

  String? _requiredText(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }

  String? _nonNegInt(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n < 0) return 'Enter a valid number';
    return null;
  }

  String? _sec0to59(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n < 0 || n > 59) return '0–59 only';
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    int timeSeconds = 0;
    if (!_isCountable) {
      final mins = int.tryParse(_minutesCtrl.text.trim()) ?? 0;
      final secs = int.tryParse(_secondsCtrl.text.trim()) ?? 0;
      timeSeconds = (mins * 60) + secs;
      if (timeSeconds <= 0) {
        // No snackbars/dialogs here; just keep it simple and safe.
        // Show inline error by forcing validation failure pattern:
        // We can instead pop up a small alert safely here, but keep minimal.
        return;
      }
    }

    final ex = Exercise(
      exerciseId: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      sets: _isCountable ? (int.tryParse(_setsCtrl.text.trim()) ?? 0) : 0,
      reps: _isCountable ? (int.tryParse(_repsCtrl.text.trim()) ?? 0) : 0,
      time: _isCountable ? 0 : timeSeconds, // stored in seconds
      isCountable: _isCountable,
    );

    Navigator.pop(context, ex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add exercise'),
        actions: [
          IconButton(
            onPressed: _submit,
            icon: const Icon(Icons.check),
            tooltip: 'Add',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: _requiredText,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                value: _isCountable,
                onChanged: (v) => setState(() => _isCountable = v),
                title: Text(_isCountable ? 'Reps/sets' : 'Time-based (minutes)'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 10),

              if (_isCountable) ...[
                TextFormField(
                  controller: _setsCtrl,
                  decoration: const InputDecoration(labelText: 'Sets'),
                  keyboardType: TextInputType.number,
                  validator: _nonNegInt,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _repsCtrl,
                  decoration: const InputDecoration(labelText: 'Reps'),
                  keyboardType: TextInputType.number,
                  validator: _nonNegInt,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minutesCtrl,
                        decoration: const InputDecoration(labelText: 'Minutes'),
                        keyboardType: TextInputType.number,
                        validator: _nonNegInt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _secondsCtrl,
                        decoration: const InputDecoration(labelText: 'Seconds'),
                        keyboardType: TextInputType.number,
                        validator: _sec0to59,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'This will run as a countdown timer on the client page.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add),
                  label: const Text('Add exercise'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}