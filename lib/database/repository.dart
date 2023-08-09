import 'package:priobike/database/database.dart';
import 'package:priobike/database/repository_object.dart';
import 'package:sqflite/sqflite.dart';

abstract class Repository {
  late AppDatabase databaseInstance;

  final String _tableName;

  Repository(this._tableName) {
    databaseInstance = AppDatabase.instance;
  }

  Future<RepositoryObject> create(RepositoryObject object) async {
    final db = await databaseInstance.database;
    final id = await db.insert(_tableName, object.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return object.copy(id: id);
  }

  Future<void> update(RepositoryObject object) async {
    final db = await databaseInstance.database;
    await db.update(
      _tableName,
      object.toMap(),
      where: '_id = ?',
      whereArgs: [object.id],
    );
  }

  RepositoryObject fromMap(Map<String, Object?> json);
}
