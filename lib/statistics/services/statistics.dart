import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/statistics/models/summary.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Statistics with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Statistics");

  var hasLoaded = false;

  /// The current summary, if any.
  Summary? currentSummary;

  /// The total distance of all rides.
  double? totalDistanceMeters;

  /// The total duration of all rides.
  double? totalDurationSeconds;

  /// The total amount of saved co2 in kg.
  double? get totalSavedCO2Kg {
    if (totalDistanceMeters == null) {
      return null;
    }
    const co2PerKm = 0.1187; // Data according to statista.com
    return (totalDistanceMeters! / 1000) * co2PerKm;
  }

  /// Get the average speed of all rides in km/h.
  double? get averageSpeedKmH {
    if (totalDistanceMeters == null || totalDurationSeconds == null || totalDurationSeconds == 0) {
      return null;
    }
    return totalDistanceMeters! / totalDurationSeconds! * 3.6;
  }

  /// The total elevation gain of all rides.
  double? totalElevationGain;

  /// The total elevation loss of all rides.
  double? totalElevationLoss;

  /// The summaries of the statistics.
  List<Summary>? summaries;

  Statistics({
    this.totalDistanceMeters,
    this.totalDurationSeconds,
    this.totalElevationGain,
    this.totalElevationLoss,
    this.summaries,
  });

  /// Reset the statistics.
  /// Note: This will only reset volatile data, not the data stored on disk.
  Future<void> reset() async {
    currentSummary = null;
    notifyListeners();
  }

  /// Load the statistics from the local storage.
  Future<void> loadStatistics() async {
    if (hasLoaded) return;
    final storage = await SharedPreferences.getInstance();

    totalDistanceMeters = storage.getDouble("priobike.statistics.totalDistanceMeters") ?? 0.0;
    totalDurationSeconds = storage.getDouble("priobike.statistics.totalDurationSeconds") ?? 0.0;
    totalElevationGain = storage.getDouble("priobike.statistics.totalElevationGain") ?? 0.0;
    totalElevationLoss = storage.getDouble("priobike.statistics.totalElevationLoss") ?? 0.0;
    summaries = (storage.getStringList("priobike.statistics.summaries") ?? [])
        .map((e) => Summary.fromJson(jsonDecode(e)))
        .toList();

    hasLoaded = true;
    notifyListeners();
  }

  /// Calculate a new summary from the build context.
  Future<void> calculateSummary(BuildContext context) async {
    await loadStatistics();

    // Get the positioning service.
    final positioning = Provider.of<Positioning>(context, listen: false);
    final positions = positioning.positions;
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
    currentSummary = Summary(
      distanceMeters: totalDistance,
      durationSeconds: totalDuration / 1000,
      elevationGain: totalElevationGain,
      elevationLoss: totalElevationLoss,
    );
    addSummary(currentSummary!);
  }

  /// Add a new summary to the statistics.
  Future<void> addSummary(Summary summary) async {
    await loadStatistics();
    if (summaries == null) {
      summaries = [summary];
    } else {
      summaries = summaries! + [summary];
    }
    await recalculateStatistics();
    await storeStatistics();
    notifyListeners();
  }

  /// Remove a summary from a specific index.
  Future<void> removeSummary(int index) async {
    await loadStatistics();
    if (summaries == null) return;
    summaries!.removeAt(index);
    await recalculateStatistics();
    await storeStatistics();
    notifyListeners();
  }

  /// Recalculate the statistics.
  Future<void> recalculateStatistics() async {
    await loadStatistics();
    if (summaries == null) return;

    totalDistanceMeters = summaries!.map((e) => e.distanceMeters).reduce((value, element) => value + element);
    totalDurationSeconds = summaries!.map((e) => e.durationSeconds).reduce((value, element) => value + element);
    totalElevationGain = summaries!.map((e) => e.elevationGain).reduce((value, element) => value + element);
    totalElevationLoss = summaries!.map((e) => e.elevationLoss).reduce((value, element) => value + element);
  }

  /// Store the statistics in the local storage.
  Future<void> storeStatistics() async {
    await loadStatistics();
    final storage = await SharedPreferences.getInstance();

    if (totalDistanceMeters != null) {
      storage.setDouble("priobike.statistics.totalDistanceMeters", totalDistanceMeters!);
    }
    if (totalDurationSeconds != null) {
      storage.setDouble("priobike.statistics.totalDurationSeconds", totalDurationSeconds!);
    }
    if (totalElevationGain != null) {
      storage.setDouble("priobike.statistics.totalElevationGain", totalElevationGain!);
    }
    if (totalElevationLoss != null) {
      storage.setDouble("priobike.statistics.totalElevationLoss", totalElevationLoss!);
    }
    if (summaries != null) {
      storage.setStringList("priobike.statistics.summaries", summaries!.map((e) => jsonEncode(e.toJson())).toList());
    }
  }
}
