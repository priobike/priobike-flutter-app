import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/discomfort.dart';

enum WarnType {
  warnSensitiveBikes,
  warnRegularBikes,
  warnRobustBikes,
  warnNone,
}

class Discomforts with ChangeNotifier {
  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// The found discomforts.
  List<DiscomfortSegment>? foundDiscomforts;

  /// The currently selected discomfort.
  DiscomfortSegment? selectedDiscomfort;

  /// The signal group clicked.
  bool trafficLightClicked = false;

  Discomforts({
    this.foundDiscomforts,
    this.selectedDiscomfort,
  });

  // Reset the discomfort service.
  Future<void> reset() async {
    needsLayout = {};
    foundDiscomforts = null;
    selectedDiscomfort = null;
    trafficLightClicked = false;
    notifyListeners();
  }

  /// Select a discomfort.
  selectDiscomfort(int idx) {
    if (foundDiscomforts == null) return;
    if (idx < 0 || idx >= foundDiscomforts!.length) return;
    selectedDiscomfort = foundDiscomforts![idx];
    super.notifyListeners();
  }

  /// Unselect a discomfort.
  unselectDiscomfort() {
    selectedDiscomfort = null;
    super.notifyListeners();
  }

  /// Select a signalGroup.
  selectTrafficLight() {
    trafficLightClicked = true;
    super.notifyListeners();
  }

  /// Unselect a signalGroup.
  unselectTrafficLight() {
    trafficLightClicked = false;
    super.notifyListeners();
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

  Future<void> findDiscomforts(GHRouteResponsePath path) async {
    final profile = getIt<Profile>();

    // Use the surface values to determine unsmooth sections.
    // See: https://wiki.openstreetmap.org/wiki/Key:surface
    final warnTypeMap = {
      "paved": WarnType.warnNone,
      "asphalt": WarnType.warnNone,
      "chipseal": WarnType.warnNone,
      "concrete": WarnType.warnNone,
      "concrete:plates": WarnType.warnRegularBikes,
      "concrete:lanes": WarnType.warnRegularBikes,
      "paving_stones": WarnType.warnNone,
      "sett": WarnType.warnRegularBikes,
      "unhewn_cobblestone": WarnType.warnRobustBikes,
      "cobblestone": WarnType.warnRobustBikes,
      "metal": WarnType.warnRegularBikes,
      "wood": WarnType.warnRegularBikes,
      "stepping_stones": WarnType.warnRobustBikes,
      "unpaved": WarnType.warnRegularBikes,
      "compacted": WarnType.warnSensitiveBikes,
      "fine_gravel": WarnType.warnRegularBikes,
      "gravel": WarnType.warnRobustBikes,
      "rock": WarnType.warnRobustBikes,
      "pebblestone": WarnType.warnRobustBikes,
      "ground": WarnType.warnRegularBikes,
      "dirt": WarnType.warnRegularBikes,
      "earth": WarnType.warnRegularBikes,
      "soil": WarnType.warnRegularBikes,
      "grass": WarnType.warnRobustBikes,
      "grass_paver": WarnType.warnRegularBikes,
      "mud": WarnType.warnRobustBikes,
      "sand": WarnType.warnRobustBikes,
      "woodchips": WarnType.warnRobustBikes,
      "snow": WarnType.warnRobustBikes,
      "ice": WarnType.warnRobustBikes,
      "salt": WarnType.warnRobustBikes,
      "clay": WarnType.warnRegularBikes,
      "tartan": WarnType.warnNone,
      "artificial_turf": WarnType.warnRobustBikes,
      "acrylic": WarnType.warnSensitiveBikes,
      "metal_grid": WarnType.warnRobustBikes,
      "carpet": WarnType.warnRegularBikes,
    };

    final translationsMap = {
      "paved": "Asphaltierter Wegabschnitt",
      "asphalt": "Asphaltierter Wegabschnitt",
      "chipseal": "Versiegelte Schotterstraße",
      "concrete": "Wegabschnitt mit Beton",
      "concrete:plates": "Wegabschnitt mit Betonplatten",
      "concrete:lanes": "Wegabschnitt Betonplatten",
      "paving_stones": "Gepflasterter Wegabschnitt",
      "sett": "Gepflasterter Wegabschnitt",
      "unhewn_cobblestone": "Kopfsteinpflaster",
      "cobblestone": "Kopfsteinpflaster",
      "metal": "Wegabschnitt auf Metall",
      "wood": "Wegabschnitt auf Holz",
      "stepping_stones": "Wegabschnitt mit Steinplatten",
      "unpaved": "Unbefestigte Straße",
      "compacted": "Unbefestigte Straße",
      "fine_gravel": "Wegabschnitt auf Feinkies",
      "gravel": "Wegabschnitt auf Kies",
      "rock": "Wegabschnitt über Felsen",
      "pebblestone": "Wegabschnitt auf Kies",
      "ground": "Unbefestigter Wegabschnitt",
      "dirt": "Unbefestigter Wegabschnitt",
      "earth": "Unbefestigter Wegabschnitt",
      "soil": "Unbefestigter Wegabschnitt",
      "grass": "Wegabschnitt über Gras",
      "grass_paver": "Wegabschnitt über Gras mit Pflastersteinen",
      "mud": "Wegabschnitt durch Matsch",
      "sand": "Wegabschnitt über Sand",
      "woodchips": "Wegabschnitt über Holzspäne",
      "snow": "Wegabschnitt über Schnee",
      "ice": "Wegabschnitt über Eis",
      "salt": "Wegabschnitt über Salz",
      "clay": "Wegabschnitt über Lehm",
      "tartan": "Wegabschnitt über Tartan",
      "artificial_turf": "Wegabschnitt über Kunstrasen",
      "acrylic": "Wegabschnitt über Acryl",
      "metal_grid": "Wegabschnitt über Metallgitter",
      "carpet": "Wegabschnitt über Teppich",
    };

    final shouldWarnMap = {
      WarnType.warnSensitiveBikes: profile.bikeType == BikeType.racingbike || profile.bikeType == BikeType.cargobike,
      WarnType.warnRegularBikes: profile.bikeType != BikeType.mountainbike,
      WarnType.warnRobustBikes: profile.bikeType == BikeType.mountainbike,
    };

    final unsmooth = List.empty(growable: true);
    for (final segment in path.details.surface) {
      if (segment.value == null) continue;
      if (segment.value is! String) continue;
      final cs = getCoordinates(segment, path);

      final warnType = warnTypeMap[segment.value!];
      if (warnType == null) continue;

      final shouldWarn = shouldWarnMap[warnType];
      if (shouldWarn == null) continue;
      if (!shouldWarn) continue;

      final translation = translationsMap[segment.value!];
      if (translation == null) continue;

      unsmooth.add(DiscomfortSegment(segment: segment, coordinates: cs, description: translation));
    }

    // Traverse the points and calculate the elevation in degrees.
    final criticalElevationSegments = List<GHSegment>.empty(growable: true);
    GHSegment? currentSegment;
    const vincenty = Distance(roundResult: false);
    for (int i = 0; i < path.points.coordinates.length - 1; i++) {
      final c1 = path.points.coordinates[i];
      final c2 = path.points.coordinates[i + 1];
      if (c1.elevation == null || c2.elevation == null) continue;
      final dist = vincenty.distance(LatLng(c1.lat, c1.lon), LatLng(c2.lat, c2.lon));
      if (dist < 50) {
        continue; // Avoid short segments due to floating point inaccuracies.
      }
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
        if (currentSegment.value == null) continue;
        if (currentSegment.value is! double) continue;
        currentSegment = GHSegment(
          from: currentSegment.from,
          to: i + 1,
          value: max(
            eleDiffPct,
            currentSegment.value! as double,
          ),
        );
      }
    }
    final criticalElevation = List.empty(growable: true);
    for (final segment in criticalElevationSegments) {
      if (segment.value == null) continue;
      if (segment.value is! double) continue;
      final cs = getCoordinates(segment, path);
      if (segment.value! > 0) {
        criticalElevation.add(
          DiscomfortSegment(
            segment: segment,
            coordinates: cs,
            description: "Wegabschnitt mit bis zu ${segment.value!.round()}% Steigung.",
          ),
        );
      } else {
        criticalElevation.add(
          DiscomfortSegment(
            segment: segment,
            coordinates: cs,
            description: "Wegabschnitt mit bis zu ${-segment.value!.round()}% Gefälle bergab.",
          ),
        );
      }
    }

    // Use the speed limit values to determine uncomfortable sections.
    // See: https://wiki.openstreetmap.org/wiki/DE:Key:maxspeed
    final unwantedSpeed = List.empty(growable: true);
    for (final segment in path.details.maxSpeed) {
      if (segment.value == null) continue;
      if (segment.value is! num) continue;
      final cs = getCoordinates(segment, path);
      if (segment.value! >= 100) {
        unwantedSpeed.add(
          DiscomfortSegment(
            segment: segment,
            coordinates: cs,
            description: "Auf einem Wegabschnitt dürfen Autos ${segment.value!.toInt()} km/h fahren.",
          ),
        );
      } else if (segment.value! <= 10) {
        unwantedSpeed.add(
          DiscomfortSegment(
            segment: segment,
            coordinates: cs,
            description: "Wegabschnitt mit Verkehrsberuhigung oder Fußgängerzone.",
          ),
        );
      }
    }

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
