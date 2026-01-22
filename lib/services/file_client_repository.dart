// lib/services/file_client_repository.dart
//
// A persistence implementation for clients using Sembast (local on-device DB).
// This matches the existing structure in /lib/services:
//   - app_database.dart
//   - client_repository.dart
//   - sembast_client_repository.dart

import 'client_repository.dart';
import 'sembast_client_repository.dart';

/// Concrete repository used by the app to persist clients.
/// Backed by Sembast through [SembastClientRepository].
class FileClientRepository extends SembastClientRepository implements ClientRepository {
  FileClientRepository() : super();
}