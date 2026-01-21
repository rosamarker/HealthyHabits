// lib/widgets/movesense_block_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../model/clients.dart';
import '../view_model/movesense_view_model.dart';

class MovesenseBlockWidget extends StatefulWidget {
  final MovesenseViewModel vm;

  /// If you provide clients + onLinkToClient, the widget can link the connected device to a client.
  final List<Client> clients;
  final ValueChanged<Client>? onLinkToClient;

  const MovesenseBlockWidget({
    super.key,
    required this.vm,
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
      animation: widget.vm,
      builder: (_, __) {
        final vm = widget.vm;

        final sensorLabel = (vm.deviceName?.isNotEmpty == true)
            ? vm.deviceName!
            : (vm.deviceId?.isNotEmpty == true ? vm.deviceId! : 'Sensor ID');

        final batteryText =
            vm.batteryPercent != null ? '${vm.batteryPercent}%' : 'battery%';

        final hrText = vm.heartRate != null ? '${vm.heartRate}' : '--';

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
                Text('$sensorLabel - $batteryText', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        if (vm.isConnected) {
                          await vm.disconnect();
                        } else {
                          await _pickAndConnect(context);
                        }
                      },
                      icon: const Icon(Icons.bluetooth),
                      label: Text(vm.isConnected ? 'Disconnect' : 'Connect'),
                    ),
                    TextButton.icon(
                      onPressed: vm.isConnected
                          ? () async {
                              if (vm.isStreaming) {
                                await vm.stopHeartRate();
                              } else {
                                await vm.startHeartRate();
                              }
                            }
                          : null,
                      icon: Icon(vm.isStreaming ? Icons.stop : Icons.play_arrow),
                      label: Text(vm.isStreaming ? 'Stop' : 'Start'),
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
                            labelText: 'Link to client',
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
                        onPressed: (!vm.isConnected ||
                                vm.deviceId == null ||
                                _selectedClientId == null)
                            ? null
                            : () {
                                final client = widget.clients
                                    .firstWhere((c) => c.clientId == _selectedClientId);

                                final updated = client.copyWith(
                                  movesenseDeviceId: vm.deviceId,
                                  movesenseDeviceName: vm.deviceName,
                                );

                                widget.onLinkToClient!(updated);

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Linked device to ${client.name}')),
                                  );
                                }
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
                child: Text('Scanning... no devices yet'),
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