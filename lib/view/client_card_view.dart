// lib/view/client_card_view.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

import '../model/clients.dart';
import '../model/recording_models.dart';
import '../services/recording_repository.dart';
import '../view_model/client_card_view_model.dart';
import '../view_model/client_list_view_model.dart';
import '../view_model/movesense_view_model.dart';
import '../view_model/recording_view_model.dart';

import '../widgets/movesense_block_widget.dart';
import '../widgets/stop_watch_timer_widget.dart';

class ClientDetailPage extends StatefulWidget {
  final ClientDetailViewModel viewModel;
  final ClientListViewModel clientListVM;
  final MovesenseViewModel movesenseVM;
  final RecordingViewModel recordingVM;

  const ClientDetailPage({
    super.key,
    required this.viewModel,
    required this.clientListVM,
    required this.movesenseVM,
    required this.recordingVM,
  });

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
          presetMillisecond: ex.time * 1000, // ex.time stored in seconds
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
    setState(() => _exerciseDone[exerciseId] = value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.viewModel.client;

    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => _exportJsonForClient(client),
            icon: const Icon(Icons.download),
            label: const Text('Export JSON'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  client.name.isNotEmpty ? client.name[0] : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 30),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Status: '),
                      Icon(Icons.circle, color: widget.viewModel.statusColor),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
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

          MovesenseBlockWidget(
            vm: widget.movesenseVM,
            recordingVM: widget.recordingVM,
            clients: [client],
            onLinkToClient: (updatedClient) {
              widget.clientListVM.updateClient(updatedClient);
              setState(() {});
            },
          ),

          const SizedBox(height: 16),
          const Text(
            'Exercises:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          if (client.exercises.isEmpty)
            const Text('No exercises added for this client.')
          else
            ...client.exercises.map((exercise) {
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
                            Text(_formatSecondsAsMinSec(exercise.time)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (exercise.isCountable)
                        Checkbox(
                          value: done,
                          onChanged: (val) => _toggleDone(exercise.exerciseId, val),
                        )
                      else if (stopWatch != null)
                        Row(
                          children: [
                            const Icon(Icons.timer, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(child: StopwatchWidget(stopWatchTimer: stopWatch)),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatSecondsAsMinSec(int secondsTotal) {
    final m = secondsTotal ~/ 60;
    final s = secondsTotal % 60;
    return 'Time: ${m}m ${s.toString().padLeft(2, '0')}s';
  }

  Future<void> _exportJsonForClient(Client client) async {
    final RecordingRepository repo = widget.recordingVM.service.repo;

    // Sessions for this client
    final sessions = (await repo.listSessions())
        .where((s) => s.clientId == client.clientId)
        .toList()
      ..sort((a, b) => b.startedAtMs.compareTo(a.startedAtMs));

    if (!mounted) return;

    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recordings found for this client.')),
      );
      return;
    }

    // Export ALL sessions for this client into one file (simpler to find/use).
    final payload = <String, Object?>{
      'client': {
        'clientId': client.clientId,
        'name': client.name,
      },
      'exportedAtMs': DateTime.now().millisecondsSinceEpoch,
      'sessions': <Object?>[],
    };

    for (final meta in sessions) {
      final samples = await repo.streamSamples(meta.sessionId).toList();

      (payload['sessions'] as List<Object?>).add({
        'meta': meta.toMap(),
        'samples': samples.map((s) => s.toMap()).toList(),
      });
    }

    final dir = await getApplicationDocumentsDirectory();
    final safeName = client.name.trim().isEmpty
        ? client.clientId
        : client.name.trim().replaceAll(RegExp(r'[^A-Za-z0-9_\-]+'), '_');

    final file = File(
      '${dir.path}/healthyhabits_${safeName}_${DateTime.now().millisecondsSinceEpoch}.json',
    );

    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(payload), flush: true);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Export complete'),
          content: SelectableText(file.path),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: file.path));
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File path copied to clipboard.')),
                );
              },
              child: const Text('Copy path'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}