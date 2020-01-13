import 'dart:math';

import 'package:bike_now_flutter/Services/setting_service.dart';
import 'package:bike_now_flutter/helper/configuration.dart';
import 'package:bike_now_flutter/models/location_plus.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqlite_api.dart';

import 'database_helper.dart';

class DatabaseLocations {
  DatabaseHelper databaseHelper = DatabaseHelper.instance;
  SettingService settingsService = SettingService.instance;

  DatabaseLocations._privateConstructor();
  static final DatabaseLocations instance =
      DatabaseLocations._privateConstructor();

  Future<int> insertLocation(LocationPlus location) async {
    if (location.longitude != 0.0 &&
        location.latitude != 0.0 &&
        await settingsService.loadLocationPush) {
      Database db = await databaseHelper.database;
      var map = <String, dynamic>{
        databaseHelper.COLUMN_SESSION: Configuration.sessionUUID,
        databaseHelper.COLUMN_RIDE_ID: Random.secure().nextDouble().toString(),
        databaseHelper.COLUMN_LSA_ID: location.nextLsaId,
        databaseHelper.COLUMN_SG_ID: location.nextSgName,
        databaseHelper.COLUMN_LOCATION_DATE: location.time,
        databaseHelper.COLUMN_LATITUDE: location.latitude,
        databaseHelper.COLUMN_LONGITUDE: location.longitude,
        databaseHelper.COLUMN_ACCURACY: location.accuracy,
        databaseHelper.COLUMN_ALTITUDE: location.altitude,
        databaseHelper.COLUMN_BEARING: location.bearing,
        databaseHelper.COLUMN_SPEED: location.speed,
        databaseHelper.COLUMN_DISTANCE: location.distanceNextSG,
        databaseHelper.COLUMN_RECOMMENDED_SPEED: location.recommendedSpeedKmh,
        databaseHelper.COLUMN_DIFF_SPEED: location.differenceSpeedKmh,
        databaseHelper.COLUMN_LAST_COUNTDOWN:
            location.lastCountdownThisLocation,
        databaseHelper.COLUMN_LAST_ALGO: location.crossAlgo,
        databaseHelper.COLUMN_LAST_INTERVAL:
            (location.locationUpdateInterval / 1000),
        databaseHelper.COLUMN_IS_TRANSMITTED: 0,
        databaseHelper.COLUMN_IS_DEBUG: location.isDebug,
        databaseHelper.COLUMN_ERROR: location.errorReportCode,
        databaseHelper.COLUMN_IS_GREEN: location.isGreen ? 1 : 0,
        databaseHelper.COLUMN_IS_SIMULATION:
            await SettingService.instance.loadSimulator ? 1 : 0,
        databaseHelper.COLUMN_NEXT_INSTRUCTION_TEXT:
            location.nextInstructionText,
        databaseHelper.COLUMN_NEXT_INSTRUCTION_SIGN:
            location.nextInstructionSig,
        databaseHelper.COLUMN_NEXT_SG: location.nextSg,
        databaseHelper.COLUMN_NEXT_GH_NODE: location.nextGhNode,
        databaseHelper.COLUMN_CREATE_DATE: DateTime.now().toString(),
      };

      int id = await db.insert(databaseHelper.TABLE_LOCATIONS, map);
      Logger.root.fine("InsertLocationPlus ID: " + id.toString());
      return id;
    }
    Logger.root.fine("ERROR INSERTING LOCATIONPLUS");

    return null;
  }

  markAsTransmitted(int id) async {
    Database db = await databaseHelper.database;

    Map<String, dynamic> row = {
      DatabaseHelper.instance.COLUMN_IS_TRANSMITTED: 1
    };

    int updateCount = await db.update(
        DatabaseHelper.instance.TABLE_LOCATIONS, row,
        where: '${DatabaseHelper.instance.COLUMN_ID} = ?', whereArgs: [id]);
  }

  Future<List<LocationPlus>> getLocationsToTransmit() async {
    Database db = await databaseHelper.database;
    String whereString = '${DatabaseHelper.instance.COLUMN_IS_TRANSMITTED} = ?';
    int argument = 0;
    List<LocationPlus> locs = [];

    List<dynamic> whereArguments = [argument];

    List<Map> result = await db.query(DatabaseHelper.instance.TABLE_LOCATIONS,
        where: whereString, whereArgs: whereArguments);

    if (result.isNotEmpty) {
      for (var row in result) {
        locs.add(getLocationPlusFromMap(row));
      }
      return locs;
    }
    return locs;
  }

  deleteAllTransmittedLocations() async {
    Database db = await databaseHelper.database;
    String whereString = '${DatabaseHelper.instance.COLUMN_IS_TRANSMITTED} = ?';
    int argument = 1;

    List<dynamic> whereArguments = [argument];

    List<Map> result = await db.query(DatabaseHelper.instance.TABLE_LOCATIONS,
        where: whereString, whereArgs: whereArguments);

    print(result.length);

    await db.delete(DatabaseHelper.instance.TABLE_LOCATIONS,
        where: whereString, whereArgs: whereArguments);
  }

  LocationPlus getLocationPlusFromMap(Map<dynamic, dynamic> map) {
    LocationPlus location = LocationPlus();
    location.id = map[databaseHelper.COLUMN_ID];
    location.rideID = map[databaseHelper.COLUMN_RIDE_ID];
    location.nextLsaId = map[databaseHelper.COLUMN_LSA_ID];
    location.nextSgName = map[databaseHelper.COLUMN_SG_ID];
    location.time = map[databaseHelper.COLUMN_LOCATION_DATE];
    location.latitude = map[databaseHelper.COLUMN_LATITUDE];
    location.longitude = map[databaseHelper.COLUMN_LONGITUDE];
    location.accuracy = map[databaseHelper.COLUMN_ACCURACY];
    location.altitude =
        (map[databaseHelper.COLUMN_ALTITUDE] as num)?.toDouble();
    location.bearing = (map[databaseHelper.COLUMN_BEARING] as num)?.toDouble();
    location.speed = map[databaseHelper.COLUMN_SPEED];
    location.distanceNextSG =
        (map[databaseHelper.COLUMN_DISTANCE] as num)?.toInt();
    location.recommendedSpeedKmh =
        (map[databaseHelper.COLUMN_RECOMMENDED_SPEED] as num)?.toInt();
    location.differenceSpeedKmh =
        (map[databaseHelper.COLUMN_DIFF_SPEED] as num)?.toDouble();
    location.lastCountdownThisLocation =
        map[databaseHelper.COLUMN_LAST_COUNTDOWN];
    location.crossAlgo = map[databaseHelper.COLUMN_LAST_ALGO];
    location.isDebug = map[databaseHelper.COLUMN_IS_DEBUG] == 1 ? true : false;
    location.errorReportCode = map[databaseHelper.COLUMN_ERROR];
    location.isGreen = map[databaseHelper.COLUMN_IS_GREEN] == 1 ? true : false;
    location.isSimulation =
        map[databaseHelper.COLUMN_IS_SIMULATION] == 1 ? true : false;
    location.nextInstructionText =
        map[databaseHelper.COLUMN_NEXT_INSTRUCTION_TEXT];
    location.nextInstructionSig =
        map[databaseHelper.COLUMN_NEXT_INSTRUCTION_SIGN];
    location.nextSg = map[databaseHelper.COLUMN_NEXT_SG];
    location.nextGhNode = map[databaseHelper.COLUMN_NEXT_GH_NODE];
    location.batteryLevel = map[databaseHelper.COLUMN_BATTERY_LVL];

    return location;
  }
//
//  Future<int> deleteRide(int id) async {
//    Database db = await databaseHelper.database;
//    int deletedID =
//    await db.delete(databaseHelper.TABLE_RIDES, where: '${databaseHelper.COLUMN_RIDE_ID} = ?', whereArgs: [id]);
//    return deletedID;
//  }
//
//  Future<Ride> queryRide(int id) async {
//    Database db = await databaseHelper.database;
//    List<Map> maps = await db.query(databaseHelper.TABLE_RIDES,
//        columns: [databaseHelper.COLUMN_RIDE_ID, databaseHelper.COLUMN_RIDES_START, databaseHelper.COLUMN_RIDES_END, databaseHelper.COLUMN_RIDES_DATE],
//        where: '$databaseHelper.COLUMN_RIDE_ID = ?',
//        whereArgs: [id]);
//    if (maps.length > 0) {
//      id = maps.first[databaseHelper.COLUMN_RIDE_ID];
//      var be1 = maps.first[databaseHelper.COLUMN_RIDES_START];
//      var be = jsonDecode(maps.first[databaseHelper.COLUMN_RIDES_START]);
//      var start = Place.fromJson(jsonDecode(maps.first[databaseHelper.COLUMN_RIDES_START]));
//      var end = Place.fromJson(jsonDecode(maps.first[databaseHelper.COLUMN_RIDES_END]));
//      var date = maps.first[databaseHelper.COLUMN_RIDES_DATE];
//
//      return Ride(start, end, date);
//    }
//    return null;
//  }
//
//  Future<List<Ride>> queryAllRides() async {
//    Database db = await databaseHelper.database;
//    List<Map> maps = await db.query(databaseHelper.TABLE_RIDES,
//        columns: [databaseHelper.COLUMN_RIDE_ID, databaseHelper.COLUMN_RIDES_START, databaseHelper.COLUMN_RIDES_END, databaseHelper.COLUMN_RIDES_DATE]);
//    if (maps.length > 0) {
//      List<Ride> rides = new List<Ride>();
//      for (var map in maps) {
//
//        var be1 = map[databaseHelper.COLUMN_RIDES_START];
//        var be = jsonDecode(map[databaseHelper.COLUMN_RIDES_START]);
//        var start = Place.fromJson(jsonDecode(map[databaseHelper.COLUMN_RIDES_START]));
//        var end = Place.fromJson(jsonDecode(map[databaseHelper.COLUMN_RIDES_END]));
//        var date = map[databaseHelper.COLUMN_RIDES_DATE];
//
//        Ride(start, end, date);
//        rides.add(Ride(start, end, date));
//      }
//      return rides;
//    }
//    return new List<Ride>();
//  }
}
