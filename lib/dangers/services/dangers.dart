import 'package:flutter/material.dart';
import 'package:priobike/dangers/models/danger.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/positioning/services/snapping.dart';
import 'package:provider/provider.dart';

class Dangers with ChangeNotifier {
  final log = Logger("Dangers");

  /// The list of reported dangers during the ride.
  List<Danger> dangers = List.empty(growable: true);

  /// Report a new danger.
  Future<void> reportDanger(BuildContext context) async {
    log.i("Reporting a new danger.");
    // Get the current position.
    final positioning = Provider.of<Positioning>(context, listen: false);
    if (positioning.lastPosition == null) {
      log.w("Cannot report a danger without a current position.");
      return;
    }
    // Get the current snapped position.
    final snapping = Provider.of<Snapping>(context, listen: false);
    if (snapping.snappedPosition == null) {
      log.w("Cannot report a danger without a current snapped position.");
      return;
    }
    // Create the danger.
    final danger = Danger(
      lat: positioning.lastPosition!.latitude,
      lng: positioning.lastPosition!.longitude,
      sLat: snapping.snappedPosition!.latitude,
      sLng: snapping.snappedPosition!.longitude,
      acc: positioning.lastPosition!.accuracy,
      time: DateTime.now().millisecondsSinceEpoch,
    );
    // Add the danger to the list.
    dangers.add(danger);
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
}
