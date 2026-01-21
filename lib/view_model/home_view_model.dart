// lib/view_model/home_view_model.dart
import '../model/clients.dart';

class CalendarViewModel {
  CalendarViewModel({List<Client> initialClients = const []})
      : _clients = List.of(initialClients);

  List<Client> _clients;

  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay = DateTime.now();

  void replaceClients(List<Client> newClients) {
    _clients = List.of(newClients);
  }

  void selectDay(DateTime day) {
    selectedDay = DateTime(day.year, day.month, day.day);
  }

  // Very simple mapping: show all clients every day unless you implement appointments.
  // Replace with your real appointment logic if needed.
  List<Client> getClientsForDay(DateTime day) {
    return List.unmodifiable(_clients);
  }
}