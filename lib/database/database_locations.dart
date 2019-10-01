import 'dart:math';

import 'package:bike_now_flutter/Services/setting_service.dart';
import 'package:bike_now_flutter/configuration.dart';
import 'package:bike_now_flutter/models/location_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:bike_now_flutter/Services/setting_service.dart';

import 'database_helper.dart';

class DatabaseLocations{
  final int MAX_NUMBER_LOCATIONS = 50;

  DatabaseHelper databaseHelper = DatabaseHelper.instance;
  SettingService settingsService = SettingService.instance;


  Future<int> insertLocation(LocationPlus location) async {

    if(location.longitude != 0.0 && location.latitude != 0.0 && await settingsService.isLocationPush){
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
        databaseHelper.COLUMN_LAST_COUNTDOWN: location.lastCountdownThisLocation,
        databaseHelper.COLUMN_LAST_ALGO: location.crossAlgo,
        databaseHelper.COLUMN_LAST_INTERVAL: (location.locationUpdateInterval / 1000),
        databaseHelper.COLUMN_IS_TRANSMITTED: 0,
        databaseHelper.COLUMN_IS_DEBUG: location.isDebug,
        databaseHelper.COLUMN_ERROR: location.errorReportCode,
        databaseHelper.COLUMN_IS_GREEN: location.isGreen ? 1 : 0,
        databaseHelper.COLUMN_IS_SIMULATION: await SettingService.instance.isSimulator ? 1 : 0,
        databaseHelper.COLUMN_NEXT_INSTRUCTION_TEXT: location.nextInstructionText,
        databaseHelper.COLUMN_NEXT_INSTRUCTION_SIGN: location.nextInstructionSig,
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