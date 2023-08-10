import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:priobike/database/test_object.dart';

part 'database.g.dart';

/// Class holding the database required for the gamification data structure. It can be accessed as a Singleton.
@DriftDatabase(tables: [TestObjects], daos: [TestDao])
class AppDatabase extends _$AppDatabase {
  /// Static instance of the class to access it as a singleton.
  static final AppDatabase instance = AppDatabase();

  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

/// Create database file at appropriate location.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
