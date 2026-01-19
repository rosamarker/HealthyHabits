import 'package:flutter/material.dart';

import '../model/clients.dart';

/// Compact, tappable client summary card used across the app.
class ClientCardWidget extends StatelessWidget {
  final Client client;
  final VoidCallback? onTap;

  const ClientCardWidget({
    super.key,
    required this.client,
    this.onTap,
  });

  Color get _statusColor {
    switch (client.active) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.yellow;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get _nextAppointmentDate {
    final dt = DateTime.fromMillisecondsSinceEpoch(client.nextAppointment * 1000);
    return '${dt.toLocal()}'.split(' ')[0];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Next appointment: $_nextAppointmentDate',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    if ((client.movesenseDeviceId ?? '').isNotEmpty ||
                        (client.movesenseDeviceName ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.bluetooth, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              client.movesenseDeviceName ?? client.movesenseDeviceId ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.circle, color: _statusColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
