// lib/view_model/client_card_view_model.dart
import 'package:flutter/material.dart';
import '../model/clients.dart';

class ClientDetailViewModel extends ChangeNotifier {
  final Client client;

  ClientDetailViewModel({required this.client});

  Color get statusColor {
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

  String get nextAppointmentFormatted {
    final seconds = client.nextAppointment;
    if (seconds <= 0) return 'Not set';

    final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}