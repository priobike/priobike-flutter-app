import 'dart:io';
import 'package:bike_now_flutter/models/ride.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bike_now_flutter/geo_coding/address_to_location_response.dart';

import 'dart:convert';

// singleton class to manage the database
class DatabaseHelper {
  // This is the actual database filename that is saved in the docs directory.
  static final _databaseName = "BikeNowLogs.db";
  // Increment this version when you need to change the schema.
  static final _databaseVersion = 10;

  // database table and column names
  final String TABLE_RIDES = 'rides';
  final String COLUMN_RIDES_START = 'start';
  final String COLUMN_RIDES_END = 'end';
  final String COLUMN_RIDES_DATE = 'date';

  final String TABLE_LOCATIONS = "locationlogs";
  final String TABLE_LSA_DATA = "lsadata";
  final String TABLE_DESTINATIONS = "destinations";
  final String TABLE_DEBUG = "debug";
  final String COLUMN_SESSION = "session";
  final String COLUMN_RIDE_ID = "rideID";
  final String COLUMN_LOCATION_DATE = "locationDate";
  final String COLUMN_LATITUDE = "lat";
  final String COLUMN_LONGITUDE = "lon";
  final String COLUMN_ACCURACY = "acc";
  final String COLUMN_ALTITUDE = "alt";
  final String COLUMN_BEARING = "bear";
  final String COLUMN_SPEED = "speed";
  final String COLUMN_DISTANCE = "dist";
  final String COLUMN_NAME = "name";
  final String COLUMN_SG_SIZE = "sg_size";
  final String COLUMN_RECOMMENDED_SPEED = "rec_speed";
  final String COLUMN_DIFF_SPEED = "diff_speed";
  final String COLUMN_LAST_COUNTDOWN = "last_countdown";
  final String COLUMN_LAST_ALGO = "algo";
  final String COLUMN_LAST_INTERVAL = "last_interval";
  final String COLUMN_IS_GREEN = "is_green";
  final String COLUMN_POSTAL_CODE = "postal_code";
  final String COLUMN_HOUSE_NUMBER = "house_number";
  final String COLUMN_ROAD = "road";
  final String COLUMN_CITY = "city";
  final String COLUMN_LSA_ID = "lsaID";
  final String COLUMN_SG_ID = "sgID";
  final String COLUMN_ID = "id";
  final String COLUMN_IS_TRANSMITTED = "isTransmitted";
  final String COLUMN_IS_SIMULATION = "isSimulation";
  final String COLUMN_IS_DEBUG = "isDebug";
  final String COLUMN_ERROR = "errorReportCode";
  final String COLUMN_CREATE_DATE = "creationDate";
  final String COLUMN_VISITATION_DATE = "visitationDate";
  final String COLUMN_FAVORITE = "favorite";

  final String COLUMN_NEXT_INSTRUCTION_TEXT = "next_instruction_text";
  final String COLUMN_NEXT_INSTRUCTION_SIGN = "next_instruction_sign";
  final String COLUMN_NEXT_SG = "next_sg";
  final String COLUMN_NEXT_GH_NODE = "next_gh_node";


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
    // Rides DB
    await db.execute('''
              CREATE TABLE $TABLE_RIDES (
                $COLUMN_RIDE_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                $COLUMN_RIDES_START TEXT NOT NULL,
                $COLUMN_RIDES_END TEXT NOT NULL,
                $COLUMN_RIDES_DATE INTEGER NOT NULL
              )
              ''');
    //Locations DB
    await db.execute('''
              CREATE TABLE $TABLE_LOCATIONS ( 
                    $COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT,  
                    $COLUMN_SESSION TEXT NOT NULL,  
                    $COLUMN_RIDE_ID TEXT NOT NULL,  
                    $COLUMN_SG_ID TEXT NOT NULL,  
                    $COLUMN_LSA_ID INTEGER NOT NULL DEFAULT '0',  
                    $COLUMN_LOCATION_DATE TEXT NOT NULL,  
                    $COLUMN_LATITUDE REAL NOT NULL,  
                    $COLUMN_LONGITUDE REAL NOT NULL,  
                    $COLUMN_ACCURACY REAL NOT NULL,  
                    $COLUMN_ALTITUDE INTEGER NOT NULL,  
                    $COLUMN_BEARING REAL NOT NULL,  
                    $COLUMN_SPEED REAL NOT NULL,  
                    $COLUMN_DISTANCE REAL NOT NULL,  
                    $COLUMN_RECOMMENDED_SPEED REAL NOT NULL,  
                    $COLUMN_DIFF_SPEED REAL NOT NULL,  
                    $COLUMN_LAST_COUNTDOWN INTEGER NOT NULL,  
                    $COLUMN_LAST_ALGO INTEGER NOT NULL,  
                    $COLUMN_LAST_INTERVAL INTEGER NOT NULL,  
                    $COLUMN_IS_GREEN INTEGER NOT NULL NULL DEFAULT \'0\',  
                    $COLUMN_IS_TRANSMITTED INTEGER NOT NULL DEFAULT \'0\',  
                    $COLUMN_IS_SIMULATION INTEGER NOT NULL DEFAULT \'0\',  
                    $COLUMN_ERROR INTEGER NOT NULL DEFAULT \'0\',  
                    $COLUMN_IS_DEBUG INTEGER NOT NULL DEFAULT \'0\',  
                    $COLUMN_NEXT_INSTRUCTION_TEXT TEXT,  
                    $COLUMN_NEXT_INSTRUCTION_SIGN TEXT,  
                    $COLUMN_NEXT_SG TEXT,  
                    $COLUMN_NEXT_GH_NODE INTEGER,
                    $COLUMN_CREATE_DATE TEXT NOT NULL  
                    )
              ''');
  }

  // Database helper methods:



}