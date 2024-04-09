import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart' hide Route;
import 'package:latlong2/latlong.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/http.dart';
import 'package:priobike/routing/messages/poi.dart';
import 'package:priobike/routing/services/profile.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/algorithm/snapper.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/discomfort.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

enum WarnType {
  warnSensitiveBikes,
  warnRegularBikes,
  warnRobustBikes,
  warnNone,
  warnAll,
}

// Use the surface values to determine unsmooth sections.
// See: https://wiki.openstreetmap.org/wiki/Key:surface
const warnTypeMap = {
  "paved": WarnType.warnNone,
  "asphalt": WarnType.warnNone,
  "chipseal": WarnType.warnNone,
  "concrete": WarnType.warnNone,
  "concrete:plates": WarnType.warnRegularBikes,
  "concrete:lanes": WarnType.warnRegularBikes,
  "paving_stones": WarnType.warnNone,
  "sett": WarnType.warnRegularBikes,
  "unhewn_cobblestone": WarnType.warnAll,
  "cobblestone": WarnType.warnAll,
  "metal": WarnType.warnRegularBikes,
  "wood": WarnType.warnRegularBikes,
  "stepping_stones": WarnType.warnAll,
  "unpaved": WarnType.warnRegularBikes,
  "compacted": WarnType.warnSensitiveBikes,
  "fine_gravel": WarnType.warnRegularBikes,
  "gravel": WarnType.warnAll,
  "rock": WarnType.warnAll,
  "pebblestone": WarnType.warnAll,
  "ground": WarnType.warnRegularBikes,
  "dirt": WarnType.warnRegularBikes,
  "earth": WarnType.warnRegularBikes,
  "soil": WarnType.warnRegularBikes,
  "grass": WarnType.warnAll,
  "grass_paver": WarnType.warnRegularBikes,
  "mud": WarnType.warnAll,
  "sand": WarnType.warnAll,
  "woodchips": WarnType.warnAll,
  "snow": WarnType.warnAll,
  "ice": WarnType.warnAll,
  "salt": WarnType.warnAll,
  "clay": WarnType.warnRegularBikes,
  "tartan": WarnType.warnNone,
  "artificial_turf": WarnType.warnAll,
  "acrylic": WarnType.warnSensitiveBikes,
  "metal_grid": WarnType.warnAll,
  "carpet": WarnType.warnRegularBikes,
};

const translationsMap = {
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

class Discomforts with ChangeNotifier {
  Discomforts();

  /// Get the coordinates for a given segment.
  List<LatLng> getCoordinates(GHSegment segment, GHRouteResponsePath path) {
    List<LatLng> coordinates = [];
    for (int i = segment.from; i <= segment.to; i++) {
      final c = path.points.coordinates[i];
      coordinates.add(LatLng(c.lat, c.lon));
    }
    return coordinates;
  }

  /// Load a pois response.
  Future<PoisResponse?> loadPoisResponse(GHRouteResponsePath path) async {
    try {
      final settings = getIt<Settings>();

      final baseUrl = settings.backend.path;
      final poisUrl = "http://$baseUrl/poi-service-backend/pois/match";
      final poisEndpoint = Uri.parse(poisUrl);
      log.i("Loading pois response from $poisUrl");

      final req = PoisRequest(
        route: path.points.coordinates.map((e) => PoiRoutePoint(lat: e.lat, lon: e.lon)).toList(),
        elongation: 50, // How long the pois should be extended for visibility
        threshold: 10, // Meters around the route
      );
      final response = await Http.post(poisEndpoint, body: json.encode(req.toJson()));

      if (response.statusCode == 200) {
        log.i("Loaded pois response from $poisUrl");
        return PoisResponse.fromJson(json.decode(response.body));
      } else {
        log.e("Failed to load pois response: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      final hint = "Failed to load pois response: $e";
      log.e(hint);
      return null;
    }
  }

  /// Find discomforts for the given route.
  Future<void> findDiscomforts(Route route) async {
    final path = route.path;

    final profile = getIt<Profile>();

    final shouldWarnMap = {
      WarnType.warnSensitiveBikes: profile.bikeType == BikeType.racingbike || profile.bikeType == BikeType.cargobike,
      WarnType.warnRegularBikes: profile.bikeType != BikeType.mountainbike,
      WarnType.warnRobustBikes: profile.bikeType == BikeType.mountainbike,
      WarnType.warnAll: true,
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
      final snapper = Snapper(nodes: route.route, position: cs[0]);
      unsmooth.add(DiscomfortSegment(
        coordinates: cs,
        description: translation,
        type: "surface",
        distanceOnRoute: snapper.snap().distanceOnRoute,
        color: const Color(0xffd7191c),
      ));
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
        final snapper = Snapper(nodes: route.route, position: cs[0]);
        criticalElevation.add(
          DiscomfortSegment(
              coordinates: cs,
              description: "${segment.value!.round()}% Steigung.",
              type: "incline",
              distanceOnRoute: snapper.snap().distanceOnRoute,
              color: const Color(0xFFfdae61)),
        );
      } else {
        final snapper = Snapper(nodes: route.route, position: cs[0]);
        criticalElevation.add(
          DiscomfortSegment(
              coordinates: cs,
              description: "${segment.value!.round()}% Gefälle bergab.",
              type: "decline",
              distanceOnRoute: snapper.snap().distanceOnRoute,
              color: const Color(0xFFffffbf)),
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
        final snapper = Snapper(nodes: route.route, position: cs[0]);
        unwantedSpeed.add(
          DiscomfortSegment(
              coordinates: cs,
              description: "${segment.value!.toInt()} km/h Tempolimit",
              type: "carspeed",
              distanceOnRoute: snapper.snap().distanceOnRoute,
              color: const Color(0xFF543005)),
        );
      } else if (segment.value! <= 10) {
        final snapper = Snapper(nodes: route.route, position: cs[0]);
        unwantedSpeed.add(
          DiscomfortSegment(
              coordinates: cs,
              description: "Fußgängerzone",
              type: "pedestrians",
              distanceOnRoute: snapper.snap().distanceOnRoute,
              color: const Color(0xFFa6d96a)),
        );
      }
    }

    // Mark segments where users need to dismount the bike.
    final dismount = List.empty(growable: true);
    for (final segment in path.details.getOffBike) {
      if (segment.value == false) continue;
      final cs = getCoordinates(segment, path);
      final snapper = Snapper(nodes: route.route, position: cs[0]);
      dismount.add(
        DiscomfortSegment(
            coordinates: cs,
            description: "Absteigen",
            type: "dismount",
            distanceOnRoute: snapper.snap().distanceOnRoute,
            color: const Color(0xFFf46d43)),
      );
    }

    PoisResponse? poisResponse;
    try {
      // Load the pois along each path.
      poisResponse = await loadPoisResponse(route.path);
    } catch (e) {
      // An error here is not that tragical. We can continue without pois.
      log.w("Failed to load pois for some paths.");
    }
    final constructions = List.empty(growable: true);
    if (poisResponse != null) {
      for (final segment in poisResponse.constructions) {
        final cs = segment.points.map((e) => LatLng(e.lat, e.lng)).toList();
        final snapper = Snapper(nodes: route.route, position: cs[0]);
        constructions.add(
          DiscomfortSegment(
              coordinates: cs,
              description: "Baustelle",
              type: "construction",
              distanceOnRoute: snapper.snap().distanceOnRoute,
              color: const Color(0xFFd73027)),
        );
      }
    }
    final accidentHotspots = List.empty(growable: true);
    if (poisResponse != null) {
      for (final segment in poisResponse.accidenthotspots) {
        final cs = segment.points.map((e) => LatLng(e.lat, e.lng)).toList();
        final snapper = Snapper(nodes: route.route, position: cs[0]);
        accidentHotspots.add(
          DiscomfortSegment(
              coordinates: cs,
              description: "Unfallschwerpunkt",
              type: "accidenthotspot",
              distanceOnRoute: snapper.snap().distanceOnRoute,
              color: const Color(0xFF4575b4)),
        );
      }
    }

    route.foundDiscomforts = List.empty(growable: true);
    route.foundDiscomforts = [
      ...dismount,
      ...accidentHotspots,
      ...constructions,
      ...unsmooth,
      ...criticalElevation,
      ...unwantedSpeed,
    ];
    route.foundDiscomforts!.sort((a, b) => a.distanceOnRoute.compareTo(b.distanceOnRoute));

    notifyListeners();
  }
}
