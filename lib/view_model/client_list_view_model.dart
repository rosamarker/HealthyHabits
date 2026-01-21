// lib/view_model/client_list_view_model.dart
import 'package:flutter/foundation.dart';
import '../model/clients.dart';

class ClientListViewModel extends ChangeNotifier {
  final List<Client> _clients = [];

  List<Client> get clients => List.unmodifiable(_clients);

  void addClient(Client client) {
    _clients.add(client);
    notifyListeners();
  }

  void removeClient(String clientId) {
    _clients.removeWhere((c) => c.clientId == clientId);
    notifyListeners();
  }

  void updateClient(Client updated) {
    final index = _clients.indexWhere((c) => c.clientId == updated.clientId);
    if (index == -1) return;
    _clients[index] = updated;
    notifyListeners();
  }
}