

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/routingNew/messages/graphhopper.dart';
import 'package:priobike/routingNew/models/discomfort.dart';
import 'package:provider/provider.dart';

class Discomforts with ChangeNotifier {
  /// The found discomforts.
  List<DiscomfortSegment>? foundDiscomforts;

  /// The currently selected discomfort.
  DiscomfortSegment? selectedDiscomfort;

  Discomforts({
    this.foundDiscomforts,
    this.selectedDiscomfort,
  });

  // Reset the discomfort service.
  Future<void> reset() async {
    foundDiscomforts = null;
    selectedDiscomfort = null;
    notifyListeners();
  }

  /// Select a discomfort.
  selectDiscomfort(DiscomfortSegment discomfortSegment) {
    selectedDiscomfort = discomfortSegment;
    notifyListeners();
  }

  /// Get the coordinates for a given segment.
  List<LatLng> getCoordinates(GHSegment segment, GHRouteResponsePath path) {
    List<LatLng> coordinates = [];
    for (int i = segment.from; i <= segment.to; i++) {
      final c = path.points.coordinates[i];
      coordinates.add(LatLng(c.lat, c.lon));
    }
    return coordinates;
  }

  Future<void> findDiscomforts(BuildContext context, GHRouteResponsePath path) async {
    final profile = Provider.of<Profile>(context, listen: false);
    
    // Use the smoothness values to determine unsmooth sections.
    // See: https://wiki.openstreetmap.org/wiki/DE:Key:smoothness
    final unsmooth = path.details.smoothness
      .map((segment) {
        if (segment.value == null) return null;
        final cs = getCoordinates(segment, path);
        if (segment.value == "impassable") {
          return DiscomfortSegment(segment: segment, coordinates: cs, description: "Nicht passierbarer Wegabschnitt.");
        } else if (segment.value == "very_horrible") {
          return DiscomfortSegment(segment: segment, coordinates: cs, description: "Wegabschnitt mit extrem schlechter Oberfläche.");
        } else if (segment.value == "horrible") {
          return DiscomfortSegment(segment: segment, coordinates: cs, description: "Wegabschnitt mit sehr schlechter Oberfläche.");
        } else if (segment.value == "very_bad") {
          return DiscomfortSegment(segment: segment, coordinates: cs, description: "Wegabschnitt mit sehr schlechter Oberfläche.");
        } else if (segment.value == "bad") {
          return DiscomfortSegment(segment: segment, coordinates: cs, description: "Wegabschnitt mit schlechter Oberfläche.");
        } else if (segment.value == "intermediate" && profile.bikeType == BikeType.racingbike) {
          return DiscomfortSegment(segment: segment, coordinates: cs, description: "Wegabschnitt, der für dein gewähltes Fahrrad (Rennrad) ungeeignet sein könnte.");
        }
      }).where((e) => e != null).map((e) => e!).toList();

    /// Use the speed limit values to determine uncomfortable sections.
    // See: https://wiki.openstreetmap.org/wiki/DE:Key:maxspeed
    final unwantedSpeed = path.details.maxSpeed
      .map((segment) {
        if (segment.value == null) return null;
        final cs = getCoordinates(segment, path);
        if (segment.value! >= 100) {
          return DiscomfortSegment(segment: segment, coordinates: cs, description: "Auf einem Wegabschnitt dürfen Autos ${segment.value} km/h fahren.");
        } else if (segment.value! <= 10) {
          return DiscomfortSegment(segment: segment, coordinates: cs, description: "Wegabschnitt mit Verkehrsberuhigung oder Fußgängerzone.");
        }
      }).where((e) => e != null).map((e) => e!).toList();
    
    foundDiscomforts = [...unsmooth, ...unwantedSpeed];
    foundDiscomforts!.sort((a, b) => a.segment.from.compareTo(b.segment.from));
    notifyListeners();
  }
}