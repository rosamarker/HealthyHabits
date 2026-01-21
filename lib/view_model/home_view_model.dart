// lib/view_model/home_view_model.dart
import 'package:flutter/foundation.dart';
import '../model/clients.dart';

class CalendarViewModel extends ChangeNotifier {
  List<Client> _clients;

  DateTime focusedDay;
  DateTime? selectedDay;

  CalendarViewModel({required List<Client> initialClients})
      : _clients = List<Client>.of(initialClients),
        focusedDay = DateTime.now(),
        selectedDay = DateTime.now();

  void selectDay(DateTime day) {
    selectedDay = day;
    notifyListeners();
  }

  void replaceClients(List<Client> clients) {
    _clients = List<Client>.of(clients);
  }

  List<Client> getClientsForDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);

    return _clients.where((c) {
      final d = DateTime.fromMillisecondsSinceEpoch(c.nextAppointment * 1000);
      final cd = DateTime(d.year, d.month, d.day);
      return cd == target;
    }).toList();
  }
}