import 'dart:convert';

import 'package:bike_now_flutter/database/database_helper.dart';
import 'package:bike_now_flutter/geo_coding/address_to_location_response.dart';
import 'package:bike_now_flutter/models/ride.dart';
import 'package:sqflite/sqlite_api.dart';

class DatabaseRides{
  DatabaseHelper databaseHelper = DatabaseHelper.instance;



  Future<int> insertRide(Ride ride) async {
    Database db = await databaseHelper.database;
    var allRide = await queryAllRides();
    var equalRidesInDatabase = allRide.where((rideItem) {
      return (rideItem.start.displayName == ride.start.displayName &&
          rideItem.end.displayName == ride.end.displayName);
    });
    if (equalRidesInDatabase.isEmpty) {

      var map = <String, dynamic>{
        databaseHelper.COLUMN_RIDES_START: ride.start.toJson().toString(),
        databaseHelper.COLUMN_RIDES_END: ride.end.toJson().toString(),
        databaseHelper.COLUMN_RIDES_DATE: ride.date
      };

      int id = await db.insert(databaseHelper.TABLE_RIDES, map);
      return id;
    }
    return null;
  }

  Future<int> deleteRide(int id) async {
    Database db = await databaseHelper.database;
    int deletedID =
    await db.delete(databaseHelper.TABLE_RIDES, where: '${databaseHelper.COLUMN_RIDE_ID} = ?', whereArgs: [id]);
    return deletedID;
  }

  Future<Ride> queryRide(int id) async {
    Database db = await databaseHelper.database;
    List<Map> maps = await db.query(databaseHelper.TABLE_RIDES,
        columns: [databaseHelper.COLUMN_RIDE_ID, databaseHelper.COLUMN_RIDES_START, databaseHelper.COLUMN_RIDES_END, databaseHelper.COLUMN_RIDES_DATE],
        where: '$databaseHelper.COLUMN_RIDE_ID = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      id = maps.first[databaseHelper.COLUMN_RIDE_ID];
      var be1 = maps.first[databaseHelper.COLUMN_RIDES_START];
      var be = jsonDecode(maps.first[databaseHelper.COLUMN_RIDES_START]);
      var start = Place.fromJson(jsonDecode(maps.first[databaseHelper.COLUMN_RIDES_START]));
      var end = Place.fromJson(jsonDecode(maps.first[databaseHelper.COLUMN_RIDES_END]));
      var date = maps.first[databaseHelper.COLUMN_RIDES_DATE];

      return Ride(start, end, date);
    }
    return null;
  }

  Future<List<Ride>> queryAllRides() async {
    Database db = await databaseHelper.database;
    List<Map> maps = await db.query(databaseHelper.TABLE_RIDES,
        columns: [databaseHelper.COLUMN_RIDE_ID, databaseHelper.COLUMN_RIDES_START, databaseHelper.COLUMN_RIDES_END, databaseHelper.COLUMN_RIDES_DATE]);
    if (maps.length > 0) {
      List<Ride> rides = new List<Ride>();
      for (var map in maps) {

        var be1 = map[databaseHelper.COLUMN_RIDES_START];
        var be = jsonDecode(map[databaseHelper.COLUMN_RIDES_START]);
        var start = Place.fromJson(jsonDecode(map[databaseHelper.COLUMN_RIDES_START]));
        var end = Place.fromJson(jsonDecode(map[databaseHelper.COLUMN_RIDES_END]));
        var date = map[databaseHelper.COLUMN_RIDES_DATE];

        Ride(start, end, date);
        rides.add(Ride(start, end, date));
      }
      return rides;
    }
    return new List<Ride>();
  }
}