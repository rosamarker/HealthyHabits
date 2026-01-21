// lib/widgets/movesense_block_widget.dart
import 'package:flutter/material.dart';
import '../view_model/movesense_view_model.dart';

class MovesenseBlockWidget extends StatelessWidget {
  final MovesenseViewModel movesenseVM;

  const MovesenseBlockWidget({super.key, required this.movesenseVM});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: movesenseVM,
      builder: (_, __) {
        final vm = movesenseVM;

        final idText = (vm.deviceId ?? 'Sensor ID').trim();
        final batteryText =
            vm.batteryPercent != null ? '${vm.batteryPercent}%' : 'battery%';

        final hrText = vm.heartRate != null ? '${vm.heartRate}' : '--';

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Movesense sensor',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '$idText - $batteryText',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Connect / Disconnect
                    TextButton.icon(
                      onPressed: () async {
                        if (vm.isConnected) {
                          await vm.disconnect();
                        } else {
                          await vm.quickConnect();
                        }
                      },
                      icon: const Icon(Icons.bluetooth),
                      label: Text(vm.isConnected ? 'Disconnect' : 'Connect'),
                    ),

                    // Start / Stop streaming
                    TextButton.icon(
                      onPressed: (!vm.isConnected)
                          ? null
                          : () async {
                              if (vm.isStreaming) {
                                await vm.stopHeartRate();
                              } else {
                                await vm.startHeartRate();
                              }
                            },
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
                    Text(
                      'HR: $hrText',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),

                if (vm.isScanning) ...[
                  const SizedBox(height: 10),
                  const Text('Scanning...', style: TextStyle(fontSize: 12)),
                ] else if (!vm.isConnected && vm.discoveredDevices.isEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'No devices found',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}