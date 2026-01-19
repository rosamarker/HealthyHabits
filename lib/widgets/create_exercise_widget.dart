// lib/widgets/create_exercise_widget.dart
import 'package:flutter/material.dart';
import '../model/clients.dart';

class ExerciseFormWidget extends StatefulWidget {
  final void Function(Exercise exercise) onCreate;

  const ExerciseFormWidget({super.key, required this.onCreate});

  @override
  State<ExerciseFormWidget> createState() => _ExerciseFormWidgetState();
}

class _ExerciseFormWidgetState extends State<ExerciseFormWidget> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _desc = TextEditingController();
  final TextEditingController _sets = TextEditingController(text: '0');
  final TextEditingController _reps = TextEditingController(text: '0');
  final TextEditingController _time = TextEditingController(text: '0');

  bool _isCountable = true;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _sets.dispose();
    _reps.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Exercise', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Exercise name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter an exercise name' : null,
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reps-based (sets & reps)'),
                value: _isCountable,
                onChanged: (v) => setState(() => _isCountable = v),
              ),

              if (_isCountable) ...[
                TextFormField(
                  controller: _sets,
                  decoration: const InputDecoration(labelText: 'Sets'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Enter sets';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reps,
                  decoration: const InputDecoration(labelText: 'Reps'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Enter reps';
                    return null;
                  },
                ),
              ] else ...[
                TextFormField(
                  controller: _time,
                  decoration: const InputDecoration(labelText: 'Time (seconds)'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Enter time in seconds';
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;

                    final exercise = Exercise(
                      exerciseId: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _name.text.trim(),
                      description: _desc.text.trim(),
                      sets: _isCountable ? int.parse(_sets.text) : 0,
                      reps: _isCountable ? int.parse(_reps.text) : 0,
                      time: _isCountable ? 0 : int.parse(_time.text),
                      isCountable: _isCountable,
                    );

                    widget.onCreate(exercise);

                    // reset for next entry
                    _name.clear();
                    _desc.clear();
                    _sets.text = '0';
                    _reps.text = '0';
                    _time.text = '0';
                    setState(() => _isCountable = true);
                  },
                  child: const Text('Add Exercise'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
