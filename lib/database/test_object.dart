import 'package:drift/drift.dart';
import 'package:priobike/database/database.dart';
part 'test_object.g.dart';

class TestObjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get number => integer()();
}

@DriftAccessor(tables: [TestObjects])
class TestDao extends DatabaseAccessor<AppDatabase> with _$TestDaoMixin {
  TestDao(AppDatabase attachedDatabase) : super(attachedDatabase);

  Future<TestObject?> create(Insertable<TestObject> object) async {
    var id = await into(db.testObjects).insert(object);
    return findById(id);
  }

  Future<TestObject?> findById(int id) {
    return (select(db.testObjects)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }
}
