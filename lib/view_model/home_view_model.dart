import '../model/clients.dart';

/* ViewModel for Calendar at the landing page */

class CalendarViewModel {
  // Client List
  final List<Client> _clients;

  // Calendar State
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  // Constructor
  CalendarViewModel({List<Client>? initialClients})
      : _clients = initialClients ?? [];

  // Public Accessors
  List<Client> get clients => _clients;

  /// Replace the internal client list with a new snapshot.
  ///
  /// The view model is intentionally kept lightweight (no ChangeNotifier)
  /// and expects the UI layer to decide when to refresh.
  void replaceClients(List<Client> clients) {
    _clients
      ..clear()
      ..addAll(clients);
  }



  /* Actions in done when using the calendar function at the landingpage */

  // Add a new client to the list
  void addClient(Client client) {
    _clients.add(client);
  }

  // Update selected and focused day
  void selectDay(DateTime day) {
    selectedDay = day;
    focusedDay = day;
  }

  // Get clients for a specific day (placeholder logic)
  List<Client> getClientsForDay(DateTime day) {
    // TODO: Replace with real filtering logic by date
    if (selectedDay != null) return _clients;
    return [];
  }
}
