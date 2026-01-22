// lib/view_model/client_list_view_model.dart
import 'package:flutter/foundation.dart';

import '../model/clients.dart';
import '../services/client_repository.dart';

class ClientListViewModel extends ChangeNotifier {
  final ClientRepository repo;

  ClientListViewModel({required this.repo});

  final List<Client> _clients = [];
  List<Client> get clients => List.unmodifiable(_clients);

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final loaded = await repo.loadAll();
    _clients
      ..clear()
      ..addAll(loaded);
    _loaded = true;
    notifyListeners();
  }

  Future<void> addClient(Client client) async {
    _clients.add(client);
    await repo.upsert(client);
    notifyListeners();
  }

  Future<void> removeClient(String clientId) async {
    _clients.removeWhere((c) => c.clientId == clientId);
    await repo.delete(clientId);
    notifyListeners();
  }

  Future<void> updateClient(Client updated) async {
    final index = _clients.indexWhere((c) => c.clientId == updated.clientId);
    if (index == -1) return;
    _clients[index] = updated;
    await repo.upsert(updated);
    notifyListeners();
  }
}