import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile with ChangeNotifier {
  var hasLoaded = false;

  /// The selected type of bike.
  BikeType? bikeType;

  /// The selected route preference.
  PreferenceType? preferenceType;

  /// The type of activity.
  ActivityType? activityType;

  /// The visibility of traffic lights
  bool? showTrafficLights;

  /// The preference of avoiding traffic lights
  bool? avoidTrafficLights;

  /// The preference of avoiding ascents
  bool? avoidAscents;

  /// The preference of avoiding traffic
  bool? avoidTraffic;

  /// The visibility of general point of interests
  bool showGeneralPOIs;

  /// The preference of setting location as start
  bool setLocationAsStart;

  /// The preference of saving search history
  bool saveSearchHistory;

  List<Waypoint>? searchHistory;

  Profile({
    this.bikeType,
    this.preferenceType,
    this.activityType,
    this.showTrafficLights,
    this.avoidTrafficLights,
    this.avoidAscents,
    this.avoidTraffic,
    this.showGeneralPOIs = true,
    this.setLocationAsStart = true,
    this.saveSearchHistory = true,
    this.searchHistory,
  });

  /// Load the stored profile.
  Future<void> loadProfile() async {
    if (hasLoaded) return;
    final storage = await SharedPreferences.getInstance();

    final bikeTypeStr = storage.getString("priobike.home.profile.bike");
    final preferenceTypeStr = storage.getString("priobike.home.profile.preferences");
    final activityTypeStr = storage.getString("priobike.home.profile.activity");
    showTrafficLights = storage.getBool("priobike.home.profile.showTrafficLights") ?? false;
    avoidTrafficLights = storage.getBool("priobike.home.profile.avoidTrafficLights") ?? false;
    avoidAscents = storage.getBool("priobike.home.profile.avoidAscents") ?? false;
    avoidTraffic = storage.getBool("priobike.home.profile.avoidTraffic") ?? false;
    showGeneralPOIs = storage.getBool("priobike.home.profile.showGeneralPOIs") ?? false;
    setLocationAsStart = storage.getBool("priobike.home.profile.setLocationAsStart") ?? true;
    saveSearchHistory = storage.getBool("priobike.home.profile.saveSearchHistory") ?? true;
    final searchHistoryStr = storage.getString("priobike.home.profile.searchHistory");

    if (bikeTypeStr != null) bikeType = BikeType.values.byName(bikeTypeStr);
    if (preferenceTypeStr != null) preferenceType = PreferenceType.values.byName(preferenceTypeStr);
    if (activityTypeStr != null) activityType = ActivityType.values.byName(activityTypeStr);
    if (searchHistoryStr != null) {
      searchHistory = (jsonDecode(searchHistoryStr) as List).map((e) => Waypoint.fromJson(e)).toList();
    }

    hasLoaded = true;
    notifyListeners();
  }

  /// Store the profile.
  Future<void> store() async {
    final storage = await SharedPreferences.getInstance();

    if (bikeType != null) await storage.setString("priobike.home.profile.bike", bikeType!.name);
    if (preferenceType != null) await storage.setString("priobike.home.profile.preferences", preferenceType!.name);
    if (activityType != null) await storage.setString("priobike.home.profile.activity", activityType!.name);
    if (showTrafficLights != null) await storage.setBool("priobike.home.profile.showTrafficLights", showTrafficLights!);
    if (avoidTrafficLights != null) {
      await storage.setBool("priobike.home.profile.avoidTrafficLights", avoidTrafficLights!);
    }
    if (avoidAscents != null) await storage.setBool("priobike.home.profile.avoidAscents", avoidAscents!);
    if (avoidTraffic != null) await storage.setBool("priobike.home.profile.avoidTraffic", avoidTraffic!);
    await storage.setBool("priobike.home.profile.showGeneralPOIs", showGeneralPOIs);
    await storage.setBool("priobike.home.profile.setLocationAsStart", setLocationAsStart);
    await storage.setBool("priobike.home.profile.avoidTraffic", saveSearchHistory);
    if (searchHistory != null) {
      final jsonStr = jsonEncode(searchHistory!.map((e) => e.toJSON()).toList());
      storage.setString("priobike.home.profile.searchHistory", jsonStr);
    }

    notifyListeners();
  }

  /// Save a new search
  Future<void> saveNewSearch(Waypoint waypoint) async {
    // Create new list or check if waypoint is in list and bring it to the front
    if (searchHistory != null) {
      if (searchHistory!.contains(waypoint)) {
        searchHistory!.remove(waypoint);
      }
      searchHistory = [waypoint, ...searchHistory!];
    } else {
      searchHistory = [waypoint];
    }

    notifyListeners();
  }
}
