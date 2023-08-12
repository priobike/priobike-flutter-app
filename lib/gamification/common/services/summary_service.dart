import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/database/database.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';

class RideSummaryService with ChangeNotifier {
  RideSummary? _lastSummary;

  RideSummary? get lastSummary => _lastSummary;

  /// Calculate a new ride summary and store it in the database.
  Future<void> calculateAndStoreSummary() async {
    // Get the positioning service.
    final positions = getIt<Positioning>().positions;
    if (positions.isEmpty) return;

    // Calculate the summary.
    final coordinates = positions.map((e) => LatLng(e.latitude, e.longitude)).toList();
    const vincenty = Distance(roundResult: false);
    // Aggregate the distance.
    var totalDistance = 0.0;
    for (var i = 0; i < coordinates.length - 1; i++) {
      totalDistance += vincenty.distance(coordinates[i], coordinates[i + 1]);
    }
    // Aggregate the elevation.
    var totalElevationGain = 0.0;
    var totalElevationLoss = 0.0;
    for (var i = 0; i < positions.length - 1; i++) {
      final elevationChange = positions[i + 1].altitude - positions[i].altitude;
      if (elevationChange > 0) {
        totalElevationGain += elevationChange;
      } else {
        totalElevationLoss += elevationChange;
      }
    }
    // Aggregate the duration.
    final now = positions.last.timestamp;
    final start = positions.first.timestamp;
    if (now == null || start == null) return;
    final totalDuration = now.difference(start).inMilliseconds;

    // Create the summary.
    var summary = RideSummariesCompanion.insert(
      distance: totalDistance,
      duration: totalDuration / 1000, //Convert to seconds
      elevationGain: totalElevationGain,
      elevationLoss: totalElevationLoss,
      averageSpeed: (totalDistance / (totalDuration / 1000)) * 3.6, //Convert to km/h
    );

    // Insert summary into database and save result in class variable.
    _lastSummary = await AppDatabase.instance.rideSummaryDao.createObject(summary);
  }

  void reset() {
    _lastSummary = null;
  }
}
