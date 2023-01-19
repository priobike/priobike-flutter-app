import 'package:flutter/material.dart';
import 'package:priobike/dangers/models/danger.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/positioning/models/snap.dart';

class Dangers with ChangeNotifier {
  final log = Logger("Dangers");

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// The list of dangers along the route.
  List<Danger> dangers = List.empty(growable: true);

  /// The distances of dangers along the route.
  List<double> dangersDistancesOnRoute = List.empty(growable: true);

  /// Report a new danger.
  Future<void> submitNew(Snap? snap, String category) async {
    if (snap == null) {
      log.w("Cannot report a danger without a position.");
      return;
    }
    log.i("Reporting a new danger.");
    // Create the danger.
    final danger = Danger(
      lat: snap.position.latitude,
      lon: snap.position.longitude,
      category: category,
    );
    // NOTE: Here we will send the danger to the server.
    // Add the danger to the list.
    dangers.add(danger);
    dangersDistancesOnRoute.add(snap.distanceOnRoute);
    notifyListeners();
  }

  /// The list of reported dangers during the ride.
  Future<void> clearDangers() async {
    dangers.clear();
    notifyListeners();
  }

  /// Reset the list of reported dangers.
  Future<void> reset() async {
    dangers = List.empty(growable: true);
    notifyListeners();
  }

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
