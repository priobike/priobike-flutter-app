import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Class holding the database required for the gamification data structure. It can be accessed as a Singleton.
class AppDatabase {
  static const String idType = "INTEGER PRIMARY KEY AUTOINCREMENT";
  static const String intType = "INTEGER NOT NULL";
  static const String dbFileName = "main.db";

  /// Static instance of the class to access it as a singleton.
  static final AppDatabase instance = AppDatabase();

  /// Instance of the database held by the class.
  static Database? _database;

  /// Returns the database. If the database is null, initialize it beforehand.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  /// Initialize, open and return the database.
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, dbFileName);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  /// Callback function for when the database is created. Creates the required database tables.
  Future _createDB(Database db, int version) async {
    initializeTestTable(db);
  }

  Future initializeTestTable(Database db) async {
    await db.execute("""
      CREATE TABLE test_table (
        id $idType,
        number $intType
      )""");
  }
}
