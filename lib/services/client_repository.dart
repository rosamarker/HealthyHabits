// lib/services/client_repository.dart
import '../model/clients.dart';

abstract class ClientRepository {
  Future<List<Client>> loadAll();
  Future<void> upsert(Client client);
  Future<void> delete(String clientId);
}