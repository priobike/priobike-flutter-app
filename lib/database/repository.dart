import 'package:drift/drift.dart';
import 'package:priobike/database/database.dart';
import 'package:priobike/database/repository_object.dart';

/// Abstract repository class to be extendet by the actual database repositories. Each
/// repository manages database transactions of a specific kind of [RepositoryObject].
abstract class Repository<T extends Insertable<dynamic>> {
  late AppDatabase _db;

  /// Name of the database table corresponding to this repository.
  final TableInfo _table;

  Repository(this._table) {
    _db = AppDatabase.instance;
  }

  /// Insert object into the database. Returns null if the object wasn't inserted or the object with the new id.
  Future<T?> create(UpdateCompanion<T> object) async {
    try {
      final id = await _db.into(_table).insert(object);
      return getById(id);
    } on Exception catch (_) {
      return null;
    }
  }

  /// Update object which is already in the database. Returns true if the change was successfully made.
  Future<bool> update(T object) async {
    return _db.update(_table).replace(object);
  }

  /// Delete object from the database by id. Returns true if an object was deleted successfully.
  Future<bool> delete(T object) async {
    var result = await _db.delete(_table).delete(object);
    return result > 0;
  }

  /// Get object from repository table by id.
  Future<T?> getById(id) {
    throw UnimplementedError();
  }

  /// Get all objects from the repositories table.
  Future<List<T>> getAll(String orderBy) async {
    return _db.select(_table).get() as Future<List<T>>;
  }
}
