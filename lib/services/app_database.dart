// lib/services/app_database.dart
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;

    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);

    final dbPath = p.join(dir.path, 'healthyhabits.db');
    _db = await databaseFactoryIo.openDatabase(dbPath);
    return _db!;
  }
}