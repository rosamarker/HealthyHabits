import '../model/clients.dart';
import 'package:flutter/material.dart';

/// ViewModel for the Client Detail Page
class ClientDetailViewModel {
  // ======= Client Data =======
  final Client client;

  // ======= Constructor =======
  ClientDetailViewModel({required this.client});

  // ======= Helpers =======
  /// Display-friendly color based on client activity status
  Color get statusColor {
    switch (client.active) {
      case 0:
        return Colors.green;   // Active
      case 1:
        return Colors.yellow;  // Caution
      case 2:
        return Colors.red;     // Inactive
      default:
        return Colors.grey;    // Unknown
    }
  }

  /// Convert timestamp to readable YYYY-MM-DD string
  String get nextAppointmentFormatted {
    final dt =
        DateTime.fromMillisecondsSinceEpoch(client.nextAppointment * 1000);
    return '${dt.toLocal()}'.split(' ')[0]; // Just the date
  }
}
