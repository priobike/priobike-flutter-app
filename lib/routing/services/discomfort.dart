import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as l;
import 'package:mapbox_gl/mapbox_gl.dart';

import 'package:priobike/home/models/profile.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/discomfort.dart';
import 'package:provider/provider.dart';

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

  Future<void> findDiscomforts(BuildContext context, GHRouteResponsePath path) async {
    final profile = Provider.of<Profile>(context, listen: false);

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
      "compacted": WarnType.warnRegularBikes,
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
      "paved": "Asphalt",
      "asphalt": "Asphalt",
      "chipseal": "Versiegelte Schotterstraße",
      "concrete": "Beton",
      "concrete:plates": "Betonplatten",
      "concrete:lanes": "Betonplatten",
      "paving_stones": "Pflastersteine",
      "sett": "Pflastersteine",
      "unhewn_cobblestone": "Ungezimmerte Kopfsteinpflaster",
      "cobblestone": "Kopfsteinpflaster",
      "metal": "Metall",
      "wood": "Holz",
      "stepping_stones": "Steinplatten",
      "unpaved": "Unbefestigte Straße",
      "compacted": "Kompakte Straße",
      "fine_gravel": "Feinkies",
      "gravel": "Kies",
      "rock": "Fels",
      "pebblestone": "Kies",
      "ground": "Erde",
      "dirt": "Erde",
      "earth": "Erde",
      "soil": "Erde",
      "grass": "Gras",
      "grass_paver": "Gras",
      "mud": "Matsch",
      "sand": "Sand",
      "woodchips": "Holzspäne",
      "snow": "Schnee",
      "ice": "Eis",
      "salt": "Salz",
      "clay": "Lehm",
      "tartan": "Tartan",
      "artificial_turf": "Kunstrasen",
      "acrylic": "Acryl",
      "metal_grid": "Metallgitter",
      "carpet": "Teppich",
    };

    final shouldWarnMap = {
      WarnType.warnSensitiveBikes: profile.bikeType == BikeType.racingbike || profile.bikeType == BikeType.cargobike,
      WarnType.warnRegularBikes: profile.bikeType != BikeType.mountainbike,
      WarnType.warnRobustBikes: profile.bikeType == BikeType.mountainbike,
    };

    final unsmooth = path.details.surface
        .map((segment) {
          if (segment.value == null) return null;
          final cs = getCoordinates(segment, path);

          final warnType = warnTypeMap[segment.value!];
          if (warnType == null) return null;

          final shouldWarn = shouldWarnMap[warnType];
          if (shouldWarn == null) return null;
          if (!shouldWarn) return null;

          final translation = translationsMap[segment.value!];
          if (translation == null) return null;

          final description = "Ungeeigneter Wegtyp für dein Fahrrad (${profile.bikeType!.description()}): $translation";
          return DiscomfortSegment(segment: segment, coordinates: cs, description: description);
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
      final dist = vincenty.distance(l.LatLng(c1.lat, c1.lon), l.LatLng(c2.lat, c2.lon));
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
        currentSegment = GHSegment(from: currentSegment.from, to: i + 1, value: max(eleDiffPct, currentSegment.value!));
      }
    }
    final criticalElevation = criticalElevationSegments.map((segment) {
      final cs = getCoordinates(segment, path);
      if (segment.value! > 0) {
        return DiscomfortSegment(
            segment: segment,
            coordinates: cs,
            description: "Wegabschnitt mit bis zu ${segment.value!.round()}% Steigung.");
      } else {
        return DiscomfortSegment(
            segment: segment,
            coordinates: cs,
            description: "Wegabschnitt mit bis zu ${-segment.value!.round()}% Gefälle bergab.");
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
                description: "Auf einem Wegabschnitt dürfen Autos ${segment.value!.toInt()} km/h fahren.");
          } else if (segment.value! <= 10) {
            return DiscomfortSegment(
                segment: segment,
                coordinates: cs,
                description: "Wegabschnitt mit Verkehrsberuhigung oder Fußgängerzone.");
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
