import 'package:flutter/material.dart';
import '../model/clients.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import '../view_model/client_card_view_model.dart';
import '../widgets/stop_watch_timer_widget.dart';

/// Client detail page UI
class ClientDetailPage extends StatefulWidget {
  final ClientDetailViewModel viewModel;

  const ClientDetailPage({super.key, required this.viewModel});

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  final Map<String, bool> _exerciseDone = {};
  final Map<String, StopWatchTimer> _stopWatches = {};

  @override
  void initState() {
    super.initState();
    for (final ex in widget.viewModel.client.exercises) {
      _exerciseDone[ex.exerciseId] = false;

      if (!ex.isCountable) {
        _stopWatches[ex.exerciseId] = StopWatchTimer(
          mode: StopWatchMode.countDown,
          presetMillisecond: ex.time * 1000,
        );
      }
    }
  }

  @override
  void dispose() {
    for (final timer in _stopWatches.values) {
      timer.dispose();
    }
    super.dispose();
  }

  void _toggleDone(String exerciseId, bool? value) {
    setState(() {
      _exerciseDone[exerciseId] = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.viewModel.client;

    return Scaffold(
      appBar: AppBar(title: Text(client.name), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header + client info
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    client.name[0],
                    style: const TextStyle(color: Colors.white, fontSize: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Status: '),
                        Icon(
                          Icons.circle,
                          color: widget.viewModel.statusColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Age: ${client.age}'),
            const SizedBox(height: 8),
            Text('Gender: ${client.gender}'),
            const SizedBox(height: 8),
            Text('Next Appointment: ${widget.viewModel.nextAppointmentFormatted}'),
            const SizedBox(height: 16),
            const Text('Motivation:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(client.motivation.isNotEmpty ? client.motivation : 'No motivation notes added.'),
            const SizedBox(height: 16),

            // Movesense association (stored on the client at creation time)
            const Text('Movesense:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.bluetooth, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (client.movesenseDeviceName ?? client.movesenseDeviceId)?.isNotEmpty == true
                        ? (client.movesenseDeviceName ?? client.movesenseDeviceId!)
                        : 'No device linked',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Exercises:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),

            // Exercises list
            Column(
              children: widget.viewModel.client.exercises.map((exercise) {
                final done = _exerciseDone[exercise.exerciseId] ?? false;
                final stopWatch = _stopWatches[exercise.exerciseId];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: name + sets/reps or time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                exercise.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: done ? TextDecoration.lineThrough : null,
                                  color: done ? Colors.grey : null,
                                ),
                              ),
                            ),
                            if (exercise.isCountable)
                              Text('${exercise.sets} sets • ${exercise.reps} reps')
                            else
                              Text('Time: ${exercise.time}s'),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Second row: checkbox or stopwatch
                        if (exercise.isCountable)
                          Row(
                            children: [
                              Checkbox(
                                value: done,
                                onChanged: (val) => _toggleDone(exercise.exerciseId, val),
                              ),
                            ],
                          )
                        else if (stopWatch != null)
                          Row(
                            children: [
                              const Icon(Icons.timer, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: StopwatchWidget(stopWatchTimer: stopWatch),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
