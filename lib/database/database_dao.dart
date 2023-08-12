import 'package:drift/drift.dart';
import 'package:priobike/database/database.dart';

/// Abstract database access object (DAO) class to be extendet by actual DAOs with corresponding [Table].
/// T specifies the [DataClass] held by the table.
abstract class DatabaseDao<T extends DataClass> extends DatabaseAccessor<AppDatabase> {
  DatabaseDao(AppDatabase attachedDatabase) : super(attachedDatabase);

  /// Corresponding table of this DAO.
  TableInfo get _table;

  /// Select statement to filter table by a given value of the primary key.
  SimpleSelectStatement _selectByPrimaryKey(dynamic value);

  /// Simple select statement to select the whole table.
  SimpleSelectStatement get _select => select(_table);

  /// Convert result list of dynamic objects to list of corrsponding data objects by casting.
  List<T> _castResultList(List<dynamic> result) => result.map((r) => r as T).toList();

  /// Insert object into the database. Returns null if the object wasn't inserted or the object with the new id.
  Future<T?> createObject(Insertable<T> object) async {
    var id = await into(_table).insert(object);
    return getObjectByPrimaryKey(id);
  }

  /// Update object which is already in the database. Returns true if the change was successfully made.
  Future<bool> updateObject(Insertable<T> object) async {
    return update(_table).replace(object);
  }

  /// Delete object from the database by id. Returns true if an object was deleted successfully.
  Future<bool> deleteObject(Insertable<T> object) async {
    return (await delete(_table).delete(object)) > 0;
  }

  /// Get specific object from corresponding table by primary key.
  Future<T?> getObjectByPrimaryKey(dynamic value) async {
    return (await _selectByPrimaryKey(value).getSingleOrNull()) as T?;
  }

  /// Get stream of  a specific object from corresponding table by primary key.
  Stream<T?> streamObjectByPrimaryKey(dynamic value) {
    return _selectByPrimaryKey(value).watchSingleOrNull().asyncMap((result) => result as T?);
  }

  /// Get all objects as a list from the corresponding table.
  Future<List<T>> getAllObjects() async {
    return _castResultList(await _select.get());
  }

  /// Get a stream of all objects as a list from the corresponding table.
  Stream<List<T>> streamAllObjects() {
    return _select.watch().asyncMap((result) => _castResultList(result));
  }
}
