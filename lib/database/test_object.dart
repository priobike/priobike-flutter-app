import 'package:drift/drift.dart';
import 'package:priobike/database/database.dart';
import 'package:priobike/database/database_dao.dart';

part 'test_object.g.dart';

class TestObjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get number => integer()();
}

@DriftAccessor(tables: [TestObjects])
class TestDao extends DatabaseDao<TestObject> with _$TestDaoMixin {
  TestDao(AppDatabase attachedDatabase) : super(attachedDatabase);

  @override
  TableInfo<Table, dynamic> get table => testObjects;

  @override
  SimpleSelectStatement selectByPrimaryKey(dynamic value) {
    return (select(testObjects)..where((tbl) => (tbl as $TestObjectsTable).id.equals(value)));
  }
}
