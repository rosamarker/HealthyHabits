// lib/services/sembast_client_repository.dart
import 'package:sembast/sembast.dart';

import '../model/clients.dart';
import 'app_database.dart';
import 'client_repository.dart';

class SembastClientRepository implements ClientRepository {
  final StoreRef<String, Map<String, Object?>> _store =
      stringMapStoreFactory.store('clients');

  @override
  Future<List<Client>> loadAll() async {
    final db = await AppDatabase.instance();
    final records = await _store.find(db);

    final clients = records
        .map((r) => Client.fromMap(Map<String, dynamic>.from(r.value)))
        .toList();

    // Stable ordering
    clients.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return clients;
  }

  @override
  Future<void> upsert(Client client) async {
    final db = await AppDatabase.instance();
    await _store.record(client.clientId).put(db, client.toMap());
  }

  @override
  Future<void> delete(String clientId) async {
    final db = await AppDatabase.instance();
    await _store.record(clientId).delete(db);
  }
}