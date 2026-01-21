// lib/view_model/client_list_view_model.dart
import 'package:flutter/foundation.dart';
import '../model/clients.dart';

class ClientListViewModel extends ChangeNotifier {
  // Singleton: one shared list across the whole app.
  static final ClientListViewModel _instance = ClientListViewModel._internal();
  factory ClientListViewModel() => _instance;
  ClientListViewModel._internal();

  final List<Client> _clients = [];

  List<Client> get clients => List.unmodifiable(_clients);

  /// Add-or-update by clientId (prevents duplicates when we both callback + return value).
  void addClient(Client client) {
    final index = _clients.indexWhere((c) => c.clientId == client.clientId);
    if (index >= 0) {
      _clients[index] = client;
    } else {
      _clients.add(client);
    }
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