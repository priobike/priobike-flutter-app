import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/algorithm/snapper.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/messages/sgselector.dart';
import 'package:priobike/routing/models/crossing.dart';
import 'package:priobike/routing/models/poi.dart';
import 'package:priobike/routing/models/route.dart' as r;
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:priobike/routing/services/poi.dart';
import 'package:priobike/routing/services/profile.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/routing.dart';
import 'package:priobike/settings/models/sg_selector.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';

/// A typed tuple for a crossing and its distance.
class TupleCrossingsDistances {
  final Crossing crossing;
  final double distance;

  TupleCrossingsDistances(this.crossing, this.distance);
}

class Routing with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Routing");

  /// A boolean indicating if the service is currently loading the route.
  bool isFetchingRoute = false;

  /// A boolean indicating if there was an error.
  bool hadErrorDuringFetch = false;

  /// A boolean indicating if waypoints are out of the city boundaries.
  bool waypointsOutOfBoundaries = false;

  /// The waypoints of the loaded route, if provided.
  List<Waypoint>? fetchedWaypoints;

  /// The bike type of the loaded route, if provided.
  BikeType? fetchedBikeType;

  /// The waypoints of the selected route, if provided.
  List<Waypoint>? selectedWaypoints;

  /// The currently selected route, if one fetched.
  r.Route? selectedRoute;

  /// All routes, if they were fetched.
  List<r.Route>? allRoutes;

  Routing({
    this.fetchedWaypoints,
    this.selectedWaypoints,
    this.selectedRoute,
    this.allRoutes,
  });

  /// Add a new waypoint. If index is provided, insert it at this index, otherwise append it at the end.
  Future<void> addWaypoint(Waypoint waypoint, [int? index]) async {
    if (selectedWaypoints == null) {
      selectedWaypoints = [waypoint];
    } else {
      index ??= selectedWaypoints!.length;
      selectedWaypoints!.insert(index, waypoint);

      // Reset the previously generated route(s) and fetched waypoints.
      selectedRoute = null;
      allRoutes = null;
      fetchedWaypoints = null;
      fetchedBikeType = null;
    }
    notifyListeners();
  }

  /// Get the best index to insert a new waypoint for the currently selected waypoints.
  int getBestWaypointInsertIndex(LatLng position) {
    if (selectedWaypoints == null) return 0;
    if (selectedWaypoints!.isEmpty) return 0;
    if (selectedWaypoints!.length == 1) return 1;

    var bestDist = double.infinity;
    var bestIdx = 0;
    for (int i = 0; i < (selectedWaypoints!.length - 1); i++) {
      // Snap the position to the segment between waypoints i and i+1
      // and calculate the distance to the snapped position.
      final w1 = selectedWaypoints![i], w2 = selectedWaypoints![i + 1];
      final p1 = LatLngAlt(w1.lat, w1.lon, 0), p2 = LatLngAlt(w2.lat, w2.lon, 0);
      final n = Snapper.calcNearestPoint(position, p1, p2);
      final d = Snapper.vincenty.distance(position, n.latLng);
      if (d < bestDist) {
        bestDist = d;
        if (n.lat == p1.lat && n.lng == p1.lng) {
          bestIdx = i; // Before the current segment
        } else if (n.lat == p2.lat && n.lng == p2.lng) {
          bestIdx = i + 2; // After the current segment
        } else {
          bestIdx = i + 1; // Inside the current segment
        }
      }
    }

    // If the first element is "Aktueller Standort" or null (also "Aktueller Standort")
    // and the new waypoint is inserted before the first element, the index must be increased by 1.
    if ((selectedWaypoints![0].address == "Aktueller Standort" || selectedWaypoints![0].address == null) &&
        bestIdx == 0) {
      bestIdx++;
    }

    return bestIdx;
  }

  /// Get the index of a waypoint in the selected waypoints.
  int getIndexOfWaypoint(Waypoint waypoint) {
    if (selectedWaypoints == null) return 0;
    return selectedWaypoints!.indexWhere((element) => element == waypoint);
  }

  /// Remove a new waypoint at index.
  Future<void> removeWaypointAt(int index) async {
    if (selectedWaypoints == null || selectedWaypoints!.isEmpty) return;
    final removedWaypoints = selectedWaypoints!.toList();
    removedWaypoints.removeAt(index);

    await selectWaypoints(removedWaypoints);

    if (selectedWaypoints!.length < 2) {
      selectedRoute = null;
      allRoutes = null;
      fetchedWaypoints = null;
      fetchedBikeType = null;

      if (!inCityBoundary(selectedWaypoints!)) {
        hadErrorDuringFetch = true;
        waypointsOutOfBoundaries = true;
      } else {
        hadErrorDuringFetch = false;
        waypointsOutOfBoundaries = false;
      }
      notifyListeners();
      return;
    }
    await loadRoutes();
  }

  /// Select new waypoints.
  Future<void> selectWaypoints(List<Waypoint>? waypoints) async {
    selectedWaypoints = waypoints;
    if ((waypoints?.length ?? 0) < 2) {
      selectedRoute = null;
      allRoutes = null;
      fetchedWaypoints = null;
      fetchedBikeType = null;
    }

    notifyListeners();
  }

  /// Resolves the OSM way IDs for the given route.
  Future<Map<int, Map<String, String>>> resolveOSMWayIds(List<GHSegment> osmWayId) async {
    final settings = getIt<Settings>();
    final baseUrl = settings.city.selectedBackend(true).path;
    final overpassPath = settings.routingEndpoint.overpassServicePath;
    final osmWayIds = osmWayId.where((e) => e.value is int).map((e) => e.value).toSet();
    var formData = "data=[out:json];(";
    for (final id in osmWayIds) {
      formData += "way($id);";
    }
    formData += ");out tags;";
    final overpassUrl = "https://$baseUrl/$overpassPath/api/interpreter";
    final overpassEndpoint = Uri.parse(overpassUrl);
    log.i("Loading OSM way IDs from $overpassUrl - $formData");

    final response = await Http.postWWWForm(overpassEndpoint, formData);
    if (response.statusCode == 200) {
      log.i("Loaded OSM way IDs from $overpassUrl");
      Map<int, Map<String, String>> osmWays = {};
      dynamic json;
      try {
        json = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (e) {
        // If the Overpass returns an error, it's send as a HTML page. Thus, jsonDecode will fail.
        log.e("Failed to parse OSM way IDs: $e");
        return {};
      }
      final elements = json["elements"];
      for (final element in elements) {
        final id = element["id"];
        final tags = element["tags"];
        osmWays[id] = Map<String, String>.from(tags);
      }
      return osmWays;
    } else {
      log.e("Failed to load OSM way IDs: ${response.statusCode} ${response.body}");
      return {}; // Not tragical, just return an empty map.
    }
  }

  /// Select the remaining waypoints.
  Future<void> selectRemainingWaypoints() async {
    final userPos = getIt<Positioning>().lastPosition;
    if (userPos == null) return;
    final userPosLatLng = LatLng(userPos.latitude, userPos.longitude);
    if (selectedWaypoints == null) return;
    // Find the waypoint segment with the shortest distance to our position.
    var shortestWaypointDistance = double.infinity;
    var shortestWaypointToIdx = 0;
    for (int i = 0; i < (selectedWaypoints!.length - 1); i++) {
      final w1 = selectedWaypoints![i], w2 = selectedWaypoints![i + 1];
      final p1 = LatLngAlt(w1.lat, w1.lon, 0), p2 = LatLngAlt(w2.lat, w2.lon, 0);
      final n = Snapper.calcNearestPoint(userPosLatLng, p1, p2);
      final d = Snapper.vincenty.distance(userPosLatLng, n.latLng);
      if (d < shortestWaypointDistance) {
        shortestWaypointDistance = d;
        shortestWaypointToIdx = i + 1;
      }
    }
    List<Waypoint> remaining = [Waypoint(userPos.latitude, userPos.longitude, address: "Aktuelle Position")];
    remaining += selectedWaypoints!.sublist(shortestWaypointToIdx);
    return await selectWaypoints(remaining);
  }

  // Reset the routing service.
  Future<void> reset() async {
    hadErrorDuringFetch = false;
    isFetchingRoute = false;
    fetchedWaypoints = null;
    fetchedBikeType = null;
    selectedWaypoints = null;
    selectedRoute = null;
    allRoutes = null;
    notifyListeners();
  }

  /// Load a SG-Selector response.
  Future<SGSelectorResponse?> loadSGSelectorResponse(GHRouteResponsePath path) async {
    try {
      final settings = getIt<Settings>();

      final baseUrl = settings.city.selectedBackend(true).path;
      String usedRoutingParameter;
      if (settings.routingEndpoint == RoutingEndpoint.graphhopperDRN) {
        usedRoutingParameter = "drn";
      } else {
        usedRoutingParameter = "osm";
      }
      final sgSelectorUrl =
          "https://$baseUrl/sg-selector-backend/routing/select?matcher=${settings.sgSelector.servicePathParameter}&routing=$usedRoutingParameter";
      final sgSelectorEndpoint = Uri.parse(sgSelectorUrl);
      log.i("Loading SG-Selector response from $sgSelectorUrl");

      final req = SGSelectorRequest(
          route: path.points.coordinates
              .map((e) => SGSelectorPosition(
                    lat: e.lat,
                    lon: e.lon,
                    alt: e.elevation ?? 0.0,
                  ))
              .toList());
      final response = await Http.post(sgSelectorEndpoint, body: json.encode(req.toJson()));

      if (response.statusCode == 200) {
        log.i("Loaded SG-Selector response from $sgSelectorUrl");
        return SGSelectorResponse.fromJson(json.decode(response.body));
      } else {
        log.e("Failed to load SG-Selector response: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      final hint = "Failed to load SG-Selector response: $e";
      log.e(hint);
      return null;
    }
  }

  /// Load a GraphHopper response.
  Future<GHRouteResponse?> loadGHRouteResponse(List<Waypoint> waypoints) async {
    try {
      final bikeType = getIt<Profile>().bikeType;
      final settings = getIt<Settings>();
      final baseUrl = settings.city.selectedBackend(true).path;
      final servicePath = settings.routingEndpoint.servicePath;
      var ghUrl = "https://$baseUrl/$servicePath/route";
      ghUrl += "?type=json";
      ghUrl += "&locale=de";
      ghUrl += "&elevation=true";
      ghUrl += "&points_encoded=false";
      ghUrl += "&profile=${bikeType.ghConfigName}";
      // Add the supported details. This must be specified in the GraphHopper config.
      ghUrl += "&details=surface";
      ghUrl += "&details=max_speed";
      ghUrl += "&details=smoothness";
      ghUrl += "&details=get_off_bike";
      ghUrl += "&details=road_class";
      ghUrl += "&details=osm_way_id";
      if (waypoints.length == 2) {
        ghUrl += "&algorithm=alternative_route";
        ghUrl += "&ch.disable=true";
      }
      for (final waypoint in waypoints) {
        ghUrl += "&point=${waypoint.lat},${waypoint.lon}";
      }
      final ghEndpoint = Uri.parse(ghUrl);
      log.i("Loading GraphHopper response from $ghUrl");

      final response = await Http.get(ghEndpoint);
      if (response.statusCode == 200) {
        log.i("Loaded GraphHopper response from $ghUrl");
        return GHRouteResponse.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        log.e("Failed to load GraphHopper response: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      final hint = "Failed to load GraphHopper response: $e";
      log.e(hint);
      return null;
    }
  }

  /// Check if all waypoints are inside of the city boundaries.
  bool inCityBoundary(List<Waypoint> waypoints) {
    final boundary = getIt<Boundary>();
    for (final waypoint in waypoints) {
      if (!boundary.checkIfPointIsInBoundary(waypoint.lon, waypoint.lat)) {
        return false;
      }
    }
    return true;
  }

  /// Load the routes from the server.
  /// To execute this method, waypoints must be given beforehand.
  /// Optional data are for example POIs along the route and the status along the route.
  Future<List<r.Route>?> loadRoutes({bool fetchOptionalData = true}) async {
    if (isFetchingRoute) return null;

    final bikeType = getIt<Profile>().bikeType;

    // Do nothing if the waypoints were already fetched (or both are null).
    if (fetchedWaypoints == selectedWaypoints && fetchedBikeType == bikeType) return null;
    if (selectedWaypoints == null || selectedWaypoints!.isEmpty) {
      hadErrorDuringFetch = false;
      notifyListeners();
      return null;
    }

    isFetchingRoute = true;
    hadErrorDuringFetch = false;
    waypointsOutOfBoundaries = false;
    notifyListeners();

    if (selectedWaypoints!.length < 2) {
      // Get the last position as the start point.
      if (getIt<Positioning>().lastPosition != null) {
        selectedWaypoints = [
          Waypoint(
            getIt<Positioning>().lastPosition!.latitude,
            getIt<Positioning>().lastPosition!.longitude,
            address: "Aktueller Standort",
          ),
          ...selectedWaypoints!,
        ];
      } else {
        hadErrorDuringFetch = true;
        waypointsOutOfBoundaries = false;
        isFetchingRoute = false;
        notifyListeners();
        return null;
      }
    }

    // Check if the waypoints are inside of the city boundaries.
    if (!inCityBoundary(selectedWaypoints!)) {
      hadErrorDuringFetch = true;
      waypointsOutOfBoundaries = true;
      isFetchingRoute = false;
      selectedRoute = null;
      notifyListeners();
      return null;
    }

    // Load the GraphHopper response.
    final ghResponse = await loadGHRouteResponse(selectedWaypoints!);
    if (ghResponse == null || ghResponse.paths.isEmpty) {
      hadErrorDuringFetch = true;
      isFetchingRoute = false;
      selectedRoute = null;
      notifyListeners();
      return null;
    }

    // Load the SG-Selector responses for each path.
    final sgSelectorResponses = await Future.wait(ghResponse.paths.map((path) => loadSGSelectorResponse(path)));
    if (sgSelectorResponses.contains(null)) {
      hadErrorDuringFetch = true;
      isFetchingRoute = false;
      selectedRoute = null;
      notifyListeners();
      return null;
    }

    if (ghResponse.paths.length != sgSelectorResponses.length) {
      hadErrorDuringFetch = true;
      isFetchingRoute = false;
      selectedRoute = null;
      notifyListeners();
      return null;
    }

    // Load the OSM tags for each path.
    var osmTags = await Future.wait(ghResponse.paths.map((path) => resolveOSMWayIds(path.details.osmWayId)));
    if (ghResponse.paths.length != osmTags.length) {
      hadErrorDuringFetch = true;
      isFetchingRoute = false;
      selectedRoute = null;
      notifyListeners();
      return null;
    }

    // Create the routes.
    final routes = ghResponse.paths
        .asMap()
        .map((i, path) {
          final sgSelectorResponse = sgSelectorResponses[i]!;
          final sgsInOrderOfRoute = List<Sg>.empty(growable: true);
          for (final waypoint in sgSelectorResponse.route) {
            if (waypoint.signalGroupId == null) continue;
            final sg = sgSelectorResponse.signalGroups[waypoint.signalGroupId];
            if (sg == null) continue;
            if (sgsInOrderOfRoute.contains(sg)) continue;
            sgsInOrderOfRoute.add(sg);
          }
          // Snap each signal group to the route and calculate the distance.
          final signalGroupsDistancesOnRoute = List<double>.empty(growable: true);
          for (final sg in sgsInOrderOfRoute) {
            final snappedSgPos = Snapper(
              position: LatLng(sg.position.lat, sg.position.lon),
              nodes: sgSelectorResponse.route,
            ).snap();
            signalGroupsDistancesOnRoute.add(snappedSgPos.distanceOnRoute);
          }
          // Snap each crossing to the route and calculate the distance.
          final crossingsDistancesOnRoute = List<double>.empty(growable: true);
          for (final crossing in sgSelectorResponse.crossings) {
            final snappedCrossingPos = Snapper(
              position: LatLng(crossing.position.lat, crossing.position.lon),
              nodes: sgSelectorResponse.route,
            ).snap();
            crossingsDistancesOnRoute.add(snappedCrossingPos.distanceOnRoute);
          }

          // Order the crossings by distance.
          final tuples = List<TupleCrossingsDistances>.empty(growable: true);
          for (var i = 0; i < crossingsDistancesOnRoute.length; i++) {
            tuples.add(TupleCrossingsDistances(sgSelectorResponse.crossings[i], crossingsDistancesOnRoute[i]));
          }
          tuples.sort((a, b) => a.distance.compareTo(b.distance));
          final orderedCrossings = List<Crossing>.empty(growable: true);
          final orderedCrossingsDistancesOnRoute = List<double>.empty(growable: true);
          for (final tuple in tuples) {
            orderedCrossings.add(tuple.crossing);
            orderedCrossingsDistancesOnRoute.add(tuple.distance);
          }

          final osmTagsForRoute = osmTags[i];

          var route = r.Route(
            idx: i,
            path: path,
            route: sgSelectorResponse.route,
            signalGroups: sgsInOrderOfRoute,
            signalGroupsDistancesOnRoute: signalGroupsDistancesOnRoute,
            crossings: orderedCrossings,
            crossingsDistancesOnRoute: orderedCrossingsDistancesOnRoute,
            osmTags: osmTagsForRoute,
          );
          // Connect the route to the start and end points.
          route = route.connected(selectedWaypoints!.first, selectedWaypoints!.last);
          return MapEntry(i, route);
        })
        .values
        .toList();

    selectedRoute = routes.first;
    allRoutes = routes;
    fetchedWaypoints = selectedWaypoints!;
    fetchedBikeType = bikeType;
    isFetchingRoute = false;

    if (fetchOptionalData) fetchOptionalRouteData();

    notifyListeners();
    return routes;
  }

  /// Fetch optional data for all routes.
  Future<void> fetchOptionalRouteData() async {
    if (allRoutes == null) return;

    final status = getIt<PredictionSGStatus>();
    final pois = getIt<Pois>();

    for (r.Route route in allRoutes!) {
      await status.fetch(route);
      status.updateStatus(route);
    }

    for (r.Route route in allRoutes!) {
      await pois.findPois(route);
    }

    // The Status and Pois must be first fetched for every route
    // before we can compare all routes with every other route to find the most unique attribute.
    for (r.Route route in allRoutes!) {
      findMostUniqueAttributeForRoute(route.idx);
    }

    notifyListeners();
  }

  /// Select a route.
  Future<void> switchToRoute(int idx) async {
    if (idx < 0 || idx >= allRoutes!.length) return;

    selectedRoute = allRoutes![idx];

    notifyListeners();
  }

  /// Returns a string with the most unique attribute for the given route compared to other routes in allRoutes.
  findMostUniqueAttributeForRoute(int idx) {
    if (allRoutes == null || allRoutes!.length <= idx) return;
    if (allRoutes!.length <= 1) return; // nothing to compare route with

    // The order of comparators defines their importance (first - most important feature)
    final comparators = [
      // Statistics related to speed advisory
      (
        "Mehr Ampeln\nverbunden",
        (r.Route r, r.Route o) {
          if (o.ok == 0) return r.ok > 0;
          return (r.ok / o.ok - 1) > 0.2;
        }
      ),
      (
        "Weniger\nKreuzungen",
        (r.Route r, r.Route o) {
          if (o.crossings.isEmpty) return r.crossings.isEmpty;
          return (o.crossings.length / r.crossings.length - 1) > 0.2;
        }
      ),
      (
        "Weniger\nGefahrenstellen",
        (r.Route r, r.Route o) {
          final lR = r.foundPois?.where((e) => e.type == POIType.accidentHotspot && e.isWarning).length ?? 0;
          final lO = o.foundPois?.where((e) => e.type == POIType.accidentHotspot && e.isWarning).length ?? 0;
          if (lR == 0) return lO > 0;
          return (lO / lR - 1) > 0.2;
        }
      ),
      (
        "Besserer\nBodenbelag",
        (r.Route r, r.Route o) {
          final lR = r.foundPois?.where((e) => e.type == POIType.surface && e.isWarning).length ?? 0;
          final lO = o.foundPois?.where((e) => e.type == POIType.surface && e.isWarning).length ?? 0;
          if (lO == 0) return lR > 0;
          return (lR / lO - 1) > 0.2;
        }
      ),
      (
        "Weniger\nBaustellen",
        (r.Route r, r.Route o) {
          final lR = r.foundPois?.where((e) => e.type == POIType.construction && e.isWarning).length ?? 0;
          final lO = o.foundPois?.where((e) => e.type == POIType.construction && e.isWarning).length ?? 0;
          if (lR == 0) return lO > 0;
          return (lO / lR - 1) > 0.2;
        }
      ),
      (
        "Mehr\nVelorouten",
        (r.Route r, r.Route o) {
          final lR = r.foundPois?.where((e) => e.type == POIType.veloroute).length ?? 0;
          final lO = o.foundPois?.where((e) => e.type == POIType.veloroute).length ?? 0;
          if (lO == 0) return lR > 0;
          return (lR / lO - 1) > 0.2;
        }
      ),
      (
        "Mehr\nGrünwellen",
        (r.Route r, r.Route o) {
          final lR = r.foundPois?.where((e) => e.type == POIType.greenWave).length ?? 0;
          final lO = o.foundPois?.where((e) => e.type == POIType.greenWave).length ?? 0;
          if (lO == 0) return lR > 0;
          return (lR / lO - 1) > 0.2;
        }
      ),
      (
        "Seltener\nAbsteigen",
        (r.Route r, r.Route o) {
          final lR = r.foundPois?.where((e) => e.type == POIType.dismount && e.isWarning).length ?? 0;
          final lO = o.foundPois?.where((e) => e.type == POIType.dismount && e.isWarning).length ?? 0;
          if (lR == 0) return lO > 0;
          return (lO / lR - 1) > 0.2;
        }
      ),
      (
        "Weniger\nFußgängerzonen",
        (r.Route r, r.Route o) {
          final lR = r.foundPois?.where((e) => e.type == POIType.pedestrians && e.isWarning).length ?? 0;
          final lO = o.foundPois?.where((e) => e.type == POIType.pedestrians && e.isWarning).length ?? 0;
          if (lR == 0) return lO > 0;
          return (lO / lR - 1) > 0.2;
        }
      ),
      (
        "Weniger\n100 km/h\nStraßen",
        (r.Route r, r.Route o) {
          final lR = r.foundPois?.where((e) => e.type == POIType.carSpeed && e.isWarning).length ?? 0;
          final lO = o.foundPois?.where((e) => e.type == POIType.carSpeed && e.isWarning).length ?? 0;
          if (lR == 0) return lO > 0;
          return (lO / lR - 1) > 0.2;
        }
      ),
      (
        "Weniger\nSteile Anstiege",
        (r.Route r, r.Route o) {
          final lR = r.foundPois?.where((e) => e.type == POIType.incline && e.isWarning).length ?? 0;
          final lO = o.foundPois?.where((e) => e.type == POIType.incline && e.isWarning).length ?? 0;
          if (lR == 0) return lO > 0;
          return (lO / lR - 1) > 0.2;
        }
      ),
      (
        "Schneller",
        (r.Route r, r.Route o) {
          if (o.path.time == 0) return r.path.time > 0;
          return (o.path.time / r.path.time - 1) > 0.2;
        }
      ),
      (
        "Kürzer",
        (r.Route r, r.Route o) {
          if (o.path.distance == 0) return r.path.distance > 0;
          return (o.path.distance / r.path.distance - 1) > 0.05;
        }
      ),
      (
        "Weniger\nSteile Abfahrten",
        (r.Route r, r.Route o) {
          final lR = r.foundPois?.where((e) => e.type == POIType.decline && e.isWarning).length ?? 0;
          final lO = o.foundPois?.where((e) => e.type == POIType.decline && e.isWarning).length ?? 0;
          if (lR == 0) return lO > 0;
          return (lO / lR - 1) > 0.4;
        }
      ),
    ];

    final route = allRoutes![idx];
    for (int i = 0; i < comparators.length; i++) {
      final (name, comparator) = comparators[i];
      final otherRoutes = allRoutes!.where((o) => o.idx != route.idx);
      final isMostUnique = otherRoutes.every((o) => comparator(route, o));
      if (isMostUnique) {
        route.mostUniqueAttribute = name;
        return;
      }
    }

    route.mostUniqueAttribute = null;
  }
}
