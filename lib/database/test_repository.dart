import 'package:priobike/database/repository.dart';
import 'package:priobike/database/test_object.dart';

class TestRepository extends Repository<TestObject> {
  TestRepository() : super("test_table");
}
