// lib/view_model/client_card_view_model.dart
import 'package:flutter/material.dart';
import '../model/clients.dart';

class ClientDetailViewModel extends ChangeNotifier {
  Client _client;

  ClientDetailViewModel({required Client client}) : _client = client;

  Client get client => _client;

  // Allow the page to reflect changes if caller updates the Client instance
  void setClient(Client updated) {
    _client = updated;
    notifyListeners();
  }

  Color get statusColor {
    switch (_client.active) {
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
    final seconds = _client.nextAppointment;
    if (seconds <= 0) return 'No appointment set';
    final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}