import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bike_now/geo_coding/address_to_location_response.dart';

import 'dart:convert';

// database table and column names
final String tableWords = 'rides';
final String columnId = '_id';
final String columnStart = 'start';
final String columnEnd = 'end';
final String columnDate = 'date';

// data model class
class Ride {
  int id;
  Place start;
  Place end;
  int date;

  Ride(this.start, this.end, this.date);

  // convenience constructor to create a Ride object
  Ride.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    var be1 = map[columnStart];
    var be = jsonDecode(map[columnStart]);
    start = Place.fromJson(jsonDecode(map[columnStart]));
    end = Place.fromJson(jsonDecode(map[columnEnd]));
    date = map[columnDate];
  }

  // convenience method to create a Map from this Ride object
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnStart: start.toJson().toString(),
      columnEnd: end.toJson().toString(),
      columnDate: date
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }
}

// singleton class to manage the database
class DatabaseHelper {
  // This is the actual database filename that is saved in the docs directory.
  static final _databaseName = "rides.db";
  // Increment this version when you need to change the schema.
  static final _databaseVersion = 7;

  // Make this a singleton class.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only allow a single open connection to the database.
  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  // open the database
  _initDatabase() async {
    // The path_provider plugin gets the right directory for Android or iOS.
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    // Open the database. Can also add an onUpdate callback parameter.
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL string to create the database
  Future _onCreate(Database db, int version) async {
    await db.execute('''
              CREATE TABLE $tableWords (
                $columnId INTEGER PRIMARY KEY,
                $columnStart TEXT NOT NULL,
                $columnEnd TEXT NOT NULL,
                $columnDate INTEGER NOT NULL
              )
              ''');
  }

  // Database helper methods:

  Future<int> insert(Ride ride) async {
    Database db = await database;
    var allRide = await queryAllRides();
    var equalRidesInDatabase = allRide.where((rideItem) {
      return (rideItem.start.displayName == ride.start.displayName &&
          rideItem.end.displayName == ride.end.displayName);
    });
    if (equalRidesInDatabase.isEmpty) {
      int id = await db.insert(tableWords, ride.toMap());
      return id;
    }
    return null;
  }

  Future<int> delete(int id) async {
    Database db = await database;
    int deletedID =
        await db.delete(tableWords, where: '$columnId = ?', whereArgs: [id]);
    return deletedID;
  }

  Future<Ride> queryRide(int id) async {
    Database db = await database;
    List<Map> maps = await db.query(tableWords,
        columns: [columnId, columnStart, columnEnd, columnDate],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return Ride.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Ride>> queryAllRides() async {
    Database db = await database;
    List<Map> maps = await db.query(tableWords,
        columns: [columnId, columnStart, columnEnd, columnDate]);
    if (maps.length > 0) {
      List<Ride> rides = new List<Ride>();
      for (var map in maps) rides.add(Ride.fromMap(map));
      return rides;
    }
    return new List<Ride>();
  }
}