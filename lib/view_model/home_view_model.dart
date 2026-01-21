// lib/view_model/home_view_model.dart
import 'package:flutter/foundation.dart';
import '../model/clients.dart';

class CalendarViewModel extends ChangeNotifier {
  DateTime focusedDay;
  DateTime? selectedDay;

  List<Client> _clients;

  CalendarViewModel({required List<Client> initialClients})
      : _clients = List.of(initialClients),
        focusedDay = DateTime.now(),
        selectedDay = DateTime.now();

  void replaceClients(List<Client> newClients) {
    _clients = List.of(newClients);
    notifyListeners();
  }

  void selectDay(DateTime day) {
    selectedDay = DateTime(day.year, day.month, day.day);
    notifyListeners();
  }

  List<Client> getClientsForDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    return _clients.where((c) {
      if (c.nextAppointment <= 0) return false;
      final dt = DateTime.fromMillisecondsSinceEpoch(c.nextAppointment * 1000);
      final d = DateTime(dt.year, dt.month, dt.day);
      return d == target;
    }).toList();
  }
}