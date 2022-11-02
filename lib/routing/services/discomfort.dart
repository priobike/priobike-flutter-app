import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as l;
import 'package:mapbox_gl/mapbox_gl.dart';

import 'package:priobike/home/models/profile.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/discomfort.dart';
import 'package:provider/provider.dart';

class Discomforts with ChangeNotifier {
  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

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
    needsLayout = {};
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

  Future<void> findDiscomforts(
      BuildContext context, GHRouteResponsePath path) async {
    final profile = Provider.of<Profile>(context, listen: false);

    // Use the smoothness values to determine unsmooth sections.
    // See: https://wiki.openstreetmap.org/wiki/DE:Key:smoothness
    final unsmooth = path.details.smoothness
        .map((segment) {
          if (segment.value == null) return null;
          final cs = getCoordinates(segment, path);
          if (segment.value == "impassable") {
            return DiscomfortSegment(
                segment: segment,
                coordinates: cs,
                description: "Nicht passierbarer Wegabschnitt.");
          } else if (segment.value == "very_horrible") {
            return DiscomfortSegment(
                segment: segment,
                coordinates: cs,
                description: "Wegabschnitt mit extrem schlechter Oberfläche.");
          } else if (segment.value == "horrible") {
            return DiscomfortSegment(
                segment: segment,
                coordinates: cs,
                description: "Wegabschnitt mit sehr schlechter Oberfläche.");
          } else if (segment.value == "very_bad") {
            return DiscomfortSegment(
                segment: segment,
                coordinates: cs,
                description: "Wegabschnitt mit sehr schlechter Oberfläche.");
          } else if (segment.value == "bad") {
            return DiscomfortSegment(
                segment: segment,
                coordinates: cs,
                description: "Wegabschnitt mit schlechter Oberfläche.");
          } else if (segment.value == "intermediate" &&
              (profile.bikeType == BikeType.racingbike ||
                  profile.bikeType == BikeType.cargobike)) {
            return DiscomfortSegment(
                segment: segment,
                coordinates: cs,
                description:
                    "Wegabschnitt, der für dein gewähltes Fahrrad (${profile.bikeType!.description()}) ungeeignet sein könnte.");
          }
        })
        .where((e) => e != null)
        .map((e) => e!)
        .toList();

    // Traverse the points and calculate the elevation in degrees.
    final criticalElevationSegments = List<GHSegment>.empty(growable: true);
    GHSegment<double>? currentSegment;
    const vincenty = l.Distance(roundResult: false);
    for (int i = 0; i < path.points.coordinates.length - 1; i++) {
      final c1 = path.points.coordinates[i];
      final c2 = path.points.coordinates[i + 1];
      if (c1.elevation == null || c2.elevation == null) continue;
      final dist =
          vincenty.distance(l.LatLng(c1.lat, c1.lon), l.LatLng(c2.lat, c2.lon));
      if (dist < 50)
        continue; // Avoid short segments due to floating point inaccuracies.
      final eleDiff = c2.elevation! - c1.elevation!;
      final eleDiffPct = eleDiff / dist * 100;
      if (eleDiffPct < 10 && eleDiffPct > -10) {
        // Finish the current segment.
        if (currentSegment != null) {
          criticalElevationSegments.add(currentSegment);
          currentSegment = null;
        }
        continue;
      }
      if (currentSegment == null) {
        currentSegment = GHSegment(from: i, to: i + 1, value: eleDiffPct);
      } else {
        currentSegment = GHSegment(
            from: currentSegment.from,
            to: i + 1,
            value: max(eleDiffPct, currentSegment.value!));
      }
    }
    final criticalElevation = criticalElevationSegments.map((segment) {
      final cs = getCoordinates(segment, path);
      if (segment.value! > 0) {
        return DiscomfortSegment(
            segment: segment,
            coordinates: cs,
            description:
                "Wegabschnitt mit bis zu ${segment.value!.round()}% Steigung.");
      } else {
        return DiscomfortSegment(
            segment: segment,
            coordinates: cs,
            description:
                "Wegabschnitt mit bis zu ${-segment.value!.round()}% Gefälle bergab.");
      }
    }).toList();

    // Use the speed limit values to determine uncomfortable sections.
    // See: https://wiki.openstreetmap.org/wiki/DE:Key:maxspeed
    final unwantedSpeed = path.details.maxSpeed
        .map((segment) {
          if (segment.value == null) return null;
          final cs = getCoordinates(segment, path);
          if (segment.value! >= 100) {
            return DiscomfortSegment(
                segment: segment,
                coordinates: cs,
                description:
                    "Auf einem Wegabschnitt dürfen Autos ${segment.value} km/h fahren.");
          } else if (segment.value! <= 10) {
            return DiscomfortSegment(
                segment: segment,
                coordinates: cs,
                description:
                    "Wegabschnitt mit Verkehrsberuhigung oder Fußgängerzone.");
          }
        })
        .where((e) => e != null)
        .map((e) => e!)
        .toList();

    foundDiscomforts = [...unsmooth, ...criticalElevation, ...unwantedSpeed];
    foundDiscomforts!.sort((a, b) => a.segment.from.compareTo(b.segment.from));
    notifyListeners();
  }

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
