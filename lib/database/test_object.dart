import 'package:drift/drift.dart';
import 'package:priobike/database/database.dart';
part 'test_object.g.dart';

class TestObjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get number => integer()();
}

@DriftAccessor(tables: [TestObjects])
class TestDao extends DatabaseDao<TestObject> with _$TestDaoMixin {
  TestDao(AppDatabase attachedDatabase) : super(attachedDatabase);

  @override
  TableInfo<Table, dynamic> get _table => testObjects;

  @override
  SimpleSelectStatement _selectByPrimaryKey(dynamic value) {
    return (select(testObjects)..where((tbl) => (tbl as $TestObjectsTable).id.equals(value)));
  }
}

abstract class DatabaseDao<T extends DataClass> extends DatabaseAccessor<AppDatabase> {
  DatabaseDao(AppDatabase attachedDatabase) : super(attachedDatabase);

  TableInfo get _table;

  SimpleSelectStatement get _select => select(_table);

  SimpleSelectStatement _selectByPrimaryKey(dynamic value);

  List<T> _castResultList(List<dynamic> result) => result.map((r) => r as T).toList();

  Future<T?> createObject(Insertable<T> object) async {
    var id = await into(_table).insert(object);
    return getObjectByPrimaryKey(id);
  }

  Future<bool> updateObject(Insertable<T> object) async {
    return update(_table).replace(object);
  }

  Future<bool> deleteObject(Insertable<T> object) async {
    return (await delete(_table).delete(object)) > 0;
  }

  Future<T?> getObjectByPrimaryKey(dynamic value) async => (await _selectByPrimaryKey(value).getSingleOrNull()) as T?;

  Stream<T?> streamObjectByPrimaryKey(dynamic value) =>
      _selectByPrimaryKey(value).watchSingleOrNull().asyncMap((result) => result as T?);

  Future<List<T>> getAllObjects() async {
    var result = await _select.get();
    return _castResultList(result);
  }

  Stream<List<T>> streamAllObjects() {
    return _select.watch().asyncMap((result) => _castResultList(result));
  }
}
