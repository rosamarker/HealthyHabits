// lib/view/client_card_view.dart
import 'package:flutter/material.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

import '../model/clients.dart';
import '../view_model/client_card_view_model.dart';
import '../view_model/client_list_view_model.dart';
import '../view_model/movement_view_model.dart';
import '../widgets/stop_watch_timer_widget.dart';

/// Client detail page UI
class ClientDetailPage extends StatefulWidget {
  final ClientDetailViewModel viewModel;

  // Selected day from the homepage calendar
  final DateTime selectedDate;

  // Needed to persist movesense link back into the list
  final ClientListViewModel clientListVM;

  // Shared BLE view model used outside CreateClientPage
  final MovesenseViewModel movesenseVM;

  const ClientDetailPage({
    super.key,
    required this.viewModel,
    required this.selectedDate,
    required this.clientListVM,
    required this.movesenseVM,
  });

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  final Map<String, bool> _exerciseDone = {};
  final Map<String, StopWatchTimer> _stopWatches = {};

  late Client _client;

  @override
  void initState() {
    super.initState();

    _client = widget.viewModel.client;

    for (final ex in _client.exercises) {
      _exerciseDone[ex.exerciseId] = false;

      if (!ex.isCountable) {
        _stopWatches[ex.exerciseId] = StopWatchTimer(
          mode: StopWatchMode.countDown,
          presetMillisecond: ex.time * 1000,
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final id = _client.movesenseDeviceId;
      if (id == null || id.isEmpty) return;

      if (widget.movesenseVM.isConnected && widget.movesenseVM.deviceId == id) {
        return;
      }

      await widget.movesenseVM.connect(id);
    });
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

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _linkMovesenseToClient({
    required String deviceId,
    required String? deviceName,
  }) async {
    final updated = _client.copyWith(
      movesenseDeviceId: deviceId,
      movesenseDeviceName:
          (deviceName != null && deviceName.trim().isNotEmpty)
              ? deviceName
              : _client.movesenseDeviceName,
    );

    widget.clientListVM.updateClient(updated);

    setState(() {
      _client = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final movesenseVM = widget.movesenseVM;

    return Scaffold(
      appBar: AppBar(title: Text(_client.name), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: movesenseVM,
          builder: (_, __) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        _client.name[0],
                        style:
                            const TextStyle(color: Colors.white, fontSize: 30),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _client.name,
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

                const SizedBox(height: 16),

                Text('Selected date: ${_formatDate(widget.selectedDate)}'),

                const SizedBox(height: 24),

                Text('Age: ${_client.age}'),
                const SizedBox(height: 8),
                Text('Gender: ${_client.gender}'),
                const SizedBox(height: 8),
                Text(
                    'Next Appointment: ${widget.viewModel.nextAppointmentFormatted}'),
                const SizedBox(height: 16),

                const Text('Motivation:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_client.motivation.isNotEmpty
                    ? _client.motivation
                    : 'No motivation notes added.'),
                const SizedBox(height: 16),

                const Text('Movesense:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bluetooth, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                movesenseVM.isConnected
                                    ? (movesenseVM.deviceName ??
                                        movesenseVM.deviceId ??
                                        'Connected')
                                    : 'Not connected',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: movesenseVM.startScan,
                              child: const Text('Scan'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: movesenseVM.isConnected
                                  ? movesenseVM.disconnect
                                  : null,
                              child: const Text('Disconnect'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Linked device: '),
                            Expanded(
                              child: Text(
                                (_client.movesenseDeviceName ??
                                            _client.movesenseDeviceId)
                                        ?.isNotEmpty ==
                                    true
                                    ? (_client.movesenseDeviceName ??
                                        _client.movesenseDeviceId!)
                                    : 'No device linked',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (movesenseVM.devices.isNotEmpty)
                          Column(
                            children: movesenseVM.devices.map((d) {
                              final title = d.name.trim().isNotEmpty
                                  ? d.name
                                  : d.id;

                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(title),
                                subtitle: d.name.trim().isNotEmpty
                                    ? Text(d.id)
                                    : null,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  await movesenseVM.connect(d.id);
                                  await _linkMovesenseToClient(
                                    deviceId: d.id,
                                    deviceName: d.name,
                                  );
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text('Exercises:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),

                Column(
                  children: widget.viewModel.client.exercises.map((exercise) {
                    final done = _exerciseDone[exercise.exerciseId] ?? false;
                    final stopWatch = _stopWatches[exercise.exerciseId];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    exercise.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      decoration: done
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: done ? Colors.grey : null,
                                    ),
                                  ),
                                ),
                                if (exercise.isCountable)
                                  Text(
                                      '${exercise.sets} sets • ${exercise.reps} reps')
                                else
                                  Text('Time: ${exercise.time}s'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (exercise.isCountable)
                              Row(
                                children: [
                                  Checkbox(
                                    value: done,
                                    onChanged: (val) =>
                                        _toggleDone(exercise.exerciseId, val),
                                  ),
                                ],
                              )
                            else if (stopWatch != null)
                              Row(
                                children: [
                                  const Icon(Icons.timer, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: StopwatchWidget(
                                        stopWatchTimer: stopWatch),
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
            );
          },
        ),
      ),
    );
  }
}