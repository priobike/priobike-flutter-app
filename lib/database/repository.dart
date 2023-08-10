import 'package:priobike/database/database.dart';
import 'package:priobike/database/repository_object.dart';
import 'package:sqflite/sqflite.dart';

/// Abstract repository class to be extendet by the actual database repositories. Each
/// repository manages database transactions of a specific kind of [RepositoryObject].
abstract class Repository<T extends RepositoryObject> {
  late AppDatabase _instance;

  /// Name of the database table corresponding to this repository.
  final String _tableName;

  Repository(this._tableName) {
    _instance = AppDatabase.instance;
  }

  /// Insert object into the database.
  Future<T> create(T object) async {
    final db = await _instance.database;
    final id = await db.insert(_tableName, object.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return object.copyWithId(id: id);
  }

  /// Update object which is already in the database.
  Future<void> update(T object) async {
    final db = await _instance.database;
    await db.update(
      _tableName,
      object.toMap(),
      where: 'id = ?',
      whereArgs: [object.id],
    );
  }
}
