// lib/widgets/movesense_block_widget.dart
import 'package:flutter/material.dart';

import '../model/clients.dart';
import '../view_model/movesense_view_model.dart';
import '../view_model/recording_view_model.dart';

class MovesenseBlockWidget extends StatefulWidget {
  final MovesenseViewModel vm;
  final RecordingViewModel recordingVM;

  final List<Client> clients;
  final ValueChanged<Client>? onLinkToClient;

  const MovesenseBlockWidget({
    super.key,
    required this.vm,
    required this.recordingVM,
    this.clients = const [],
    this.onLinkToClient,
  });

  @override
  State<MovesenseBlockWidget> createState() => _MovesenseBlockWidgetState();
}

class _MovesenseBlockWidgetState extends State<MovesenseBlockWidget> {
  String? _selectedClientId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.vm, widget.recordingVM]),
      builder: (_, __) {
        final vm = widget.vm;
        final rec = widget.recordingVM;

        final idOrName = (vm.deviceName?.isNotEmpty == true)
            ? vm.deviceName!
            : (vm.deviceId?.isNotEmpty == true ? vm.deviceId! : 'Sensor');

        // Show battery state (normal/low/--)
        final batteryText = vm.batteryStateText; // "normal" / "low" / "--"

        final hrText = vm.heartRate != null ? '${vm.heartRate}' : '--';

        final statusLine = vm.isConnecting
            ? 'Connecting...'
            : (vm.isConnected ? 'Connected' : 'Not connected');

        final canTapConnect = !vm.isConnecting;

        final recordingLine = rec.isRecording
            ? 'Recording • ${rec.elapsed.inSeconds}s • ${rec.sampleCount} samples'
            : 'Not recording';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Movesense sensor',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    children: [
                      TextSpan(text: '$idOrName\n'),
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(Icons.battery_full, size: 18),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(text: batteryText),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLine,
                  style: TextStyle(
                    color: vm.isConnecting ? Colors.orange : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  recordingLine,
                  style: TextStyle(
                    color: rec.isRecording ? Colors.redAccent : null,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Avoid overflow: Wrap instead of Row
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: !canTapConnect
                          ? null
                          : () async {
                              if (vm.isConnected) {
                                await vm.disconnect();
                              } else {
                                await _pickAndConnect(context);
                              }
                            },
                      icon: const Icon(Icons.bluetooth),
                      label: Text(
                        vm.isConnecting
                            ? 'Connecting'
                            : (vm.isConnected ? 'Disconnect' : 'Connect'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: vm.isConnected && !vm.isConnecting
                          ? () async {
                              if (vm.isStreaming) {
                                await vm.stopHeartRate();
                              } else {
                                await vm.startHeartRate();
                              }
                            }
                          : null,
                      icon: Icon(vm.isStreaming ? Icons.stop : Icons.play_arrow),
                      label: Text(
                        vm.isStreaming ? 'Stop HR' : 'Start HR',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: vm.isConnected && vm.isStreaming
                          ? () async {
                              if (rec.isRecording) {
                                await rec.stop();
                              } else {
                                await rec.start(clientId: _selectedClientId);
                              }
                            }
                          : null,
                      icon: Icon(rec.isRecording ? Icons.stop_circle : Icons.fiber_manual_record),
                      label: Text(
                        rec.isRecording ? 'Stop rec' : 'Record',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('HR: $hrText', style: const TextStyle(fontSize: 18)),
                  ],
                ),

                if (widget.onLinkToClient != null && widget.clients.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedClientId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Link / Record for client',
                            border: OutlineInputBorder(),
                          ),
                          items: widget.clients
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.clientId,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedClientId = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: (!vm.isConnected || vm.deviceId == null || _selectedClientId == null)
                            ? null
                            : () {
                                final client = widget.clients.firstWhere(
                                  (c) => c.clientId == _selectedClientId,
                                );

                                final updated = client.copyWith(
                                  movesenseDeviceId: vm.deviceId,
                                  movesenseDeviceName: vm.deviceName,
                                );

                                widget.onLinkToClient!(updated);

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Linked device to ${client.name}')),
                                );
                              },
                        child: const Text('Link'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndConnect(BuildContext context) async {
    final vm = widget.vm;

    await vm.startScan();
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return AnimatedBuilder(
          animation: vm,
          builder: (_, __) {
            final devices = vm.foundDevices;

            if (devices.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Scanning for Movesense devices...'),
              );
            }

            return ListView.separated(
              itemCount: devices.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final d = devices[i];
                return ListTile(
                  leading: const Icon(Icons.watch),
                  title: Text(d.name.isNotEmpty ? d.name : d.id),
                  subtitle: Text(d.id),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await vm.connect(d);
                  },
                );
              },
            );
          },
        );
      },
    );

    await vm.stopScan();
  }
}