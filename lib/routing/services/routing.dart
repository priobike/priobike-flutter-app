import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/routing/services/profile.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/algorithm/snapper.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/messages/sgselector.dart';
import 'package:priobike/routing/models/crossing.dart';
import 'package:priobike/routing/models/route.dart' as r;
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:priobike/routing/services/discomfort.dart';
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

      final discomforts = getIt<Discomforts>();
      await discomforts.reset();
    }

    notifyListeners();
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

      final baseUrl = settings.backend.path;
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
      final baseUrl = settings.backend.path;
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
  Future<List<r.Route>?> loadRoutes() async {
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
      notifyListeners();
      return null;
    }

    // Load the GraphHopper response.
    final ghResponse = await loadGHRouteResponse(selectedWaypoints!);
    if (ghResponse == null || ghResponse.paths.isEmpty) {
      hadErrorDuringFetch = true;
      isFetchingRoute = false;
      notifyListeners();
      return null;
    }

    // Load the SG-Selector responses for each path.
    final sgSelectorResponses = await Future.wait(ghResponse.paths.map((path) => loadSGSelectorResponse(path)));
    if (sgSelectorResponses.contains(null)) {
      hadErrorDuringFetch = true;
      isFetchingRoute = false;
      notifyListeners();
      return null;
    }

    if (ghResponse.paths.length != sgSelectorResponses.length) {
      hadErrorDuringFetch = true;
      isFetchingRoute = false;
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

          var route = r.Route(
            id: i,
            path: path,
            route: sgSelectorResponse.route,
            signalGroups: sgsInOrderOfRoute,
            signalGroupsDistancesOnRoute: signalGroupsDistancesOnRoute,
            crossings: orderedCrossings,
            crossingsDistancesOnRoute: orderedCrossingsDistancesOnRoute,
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

    final status = getIt<PredictionSGStatus>();
    for (r.Route route in routes) {
      await status.fetch(route);
      route.ok = status.calculateStatus(route)["ok"]!;
      route.mostUniqueAttribute = await findMostUniqueAttributeForRoute(route.id);
    }

    final discomforts = getIt<Discomforts>();
    await discomforts.findDiscomforts(routes.first);

    status.updateStatus(routes.first);

    notifyListeners();
    return routes;
  }

  /// Load the routes from a route shortcut from the server (lightweight).
  /// Note: this function should only be used for migration.
  Future<r.Route?> loadRouteFromShortcutRouteForMigration(ShortcutRoute shortcutRoute) async {
    if (isFetchingRoute) return null;

    isFetchingRoute = true;
    hadErrorDuringFetch = false;
    waypointsOutOfBoundaries = false;
    notifyListeners();

    // Do not allow shortcuts with waypoints length < 2.
    if (shortcutRoute.waypoints.length < 2) {
      hadErrorDuringFetch = true;
      waypointsOutOfBoundaries = false;
      isFetchingRoute = false;
      notifyListeners();
      return null;
    }

    // Check if the waypoints are inside of the city boundaries.
    if (!inCityBoundary(shortcutRoute.waypoints)) {
      hadErrorDuringFetch = true;
      waypointsOutOfBoundaries = true;
      isFetchingRoute = false;
      notifyListeners();
      return null;
    }

    // Load the GraphHopper response.
    final ghResponse = await loadGHRouteResponse(shortcutRoute.waypoints);
    if (ghResponse == null || ghResponse.paths.isEmpty) {
      hadErrorDuringFetch = true;
      isFetchingRoute = false;
      notifyListeners();
      return null;
    }

    // Create the routes.
    final routes = ghResponse.paths
        .asMap()
        .map((i, path) {
          final sgsInOrderOfRoute = List<Sg>.empty(growable: true);
          // Snap each signal group to the route and calculate the distance.
          final signalGroupsDistancesOnRoute = List<double>.empty(growable: true);

          // Order the crossings by distance.
          final tuples = List<TupleCrossingsDistances>.empty(growable: true);

          tuples.sort((a, b) => a.distance.compareTo(b.distance));
          final orderedCrossings = List<Crossing>.empty(growable: true);
          final orderedCrossingsDistancesOnRoute = List<double>.empty(growable: true);
          for (final tuple in tuples) {
            orderedCrossings.add(tuple.crossing);
            orderedCrossingsDistancesOnRoute.add(tuple.distance);
          }

          var route = r.Route(
            id: i,
            path: path,
            route: [],
            signalGroups: sgsInOrderOfRoute,
            signalGroupsDistancesOnRoute: signalGroupsDistancesOnRoute,
            crossings: orderedCrossings,
            crossingsDistancesOnRoute: orderedCrossingsDistancesOnRoute,
          );
          // Connect the route to the start and end points.
          route = route.connected(shortcutRoute.waypoints.first, shortcutRoute.waypoints.last);
          return MapEntry(i, route);
        })
        .values
        .toList();

    isFetchingRoute = false;

    notifyListeners();
    return routes.first;
  }

  /// Select a route.
  Future<void> switchToRoute(int idx) async {
    if (idx < 0 || idx >= allRoutes!.length) return;

    selectedRoute = allRoutes![idx];

    final discomforts = getIt<Discomforts>();
    await discomforts.findDiscomforts(selectedRoute!);

    final status = getIt<PredictionSGStatus>();
    for (r.Route route in allRoutes!) {
      await status.fetch(route);
    }
    status.updateStatus(selectedRoute!);

    notifyListeners();
  }

  /// Returns a string with the most unique attribute for the given route compared to other routes in allRoutes.
  Future<String?> findMostUniqueAttributeForRoute(int id) async {
    if (allRoutes == null && allRoutes!.length <= id) return null;
    if (allRoutes!.length <= 1) return null; // nothing to compare route with

    final discomforts = getIt<Discomforts>();

    final r.Route route = allRoutes![id];
    final int numOkSGs = route.ok ?? 0;
    final int numCrossings = route.crossings.length;
    final int numDiscomforts = (await discomforts.getDiscomfortsForRoute(route)).length;
    final int numPushBike = route.path.details.getOffBike.length;
    final int arrivalTime = route.path.time;
    final double distance = route.path.distance;

    const int thresholdNumOkSGsInPtc = 20;
    const int thresholdCrossingsInPtc = 20;
    const int thresholdDiscomfortsInPtc = 20;
    const int thresholdPushBikeAbsolute = 1;
    const int thresholdTimeInPtc = 20;
    const int thresholdDistanceInPtc = 15;

    // print everything
    print("Charly ====================================");
    print("Charly id: $id");
    print("Charly numOkSGs: $numOkSGs");
    print("Charly numCrossings: $numCrossings");
    print("Charly numDiscomforts: $numDiscomforts");
    print("Charly numPushBike: $numPushBike");
    print("Charly arrivalTime: $arrivalTime");
    print("Charly distance: $distance");

    final Map<String, bool> hasBestAttribute = {
      "numOkSGs": numOkSGs > 0,
      "numCrossings": true,
      "numDiscomforts": true,
      "numPushBike": true,
      "earliestArrival": true,
      "shortest": true,
    };

    final Map<String, (r.Route?, double)> secondBest = {
      // Initialize with negative or positive infinity depending on if higher or lower values are worse
      "numOkSGs": (null, double.negativeInfinity),
      "numCrossings": (null, double.infinity),
      "numDiscomforts": (null, double.infinity),
      "numPushBike": (null, double.infinity),
      "earliestArrival": (null, double.infinity),
      "shortest": (null, double.infinity),
    };

    // Find if route has a unique attribute and find the second best route for each attribute
    for (final r.Route otherRoute in allRoutes!) {
      if (otherRoute.id == id) continue;

      // Number Ok-SGs => more is better
      if (otherRoute.ok != null) {
        if (otherRoute.ok! >= numOkSGs) {
          hasBestAttribute["numOkSGs"] = false;
        }
        if (secondBest["numOkSGs"] == null ||
            secondBest["numOkSGs"]!.$1 == null ||
            otherRoute.ok! > secondBest["numOkSGs"]!.$2) {
          secondBest["numOkSGs"] = (otherRoute, otherRoute.ok!.toDouble());
        }
      }

      // Number Crossings => less is better
      if (otherRoute.crossings.length <= numCrossings) hasBestAttribute["numCrossings"] = false;
      if (secondBest["numCrossings"] == null ||
          secondBest["numCrossings"]!.$1 == null ||
          otherRoute.crossings.length < secondBest["numCrossings"]!.$2) {
        secondBest["numCrossings"] = (otherRoute, otherRoute.crossings.length.toDouble());
      }

      // Number Discomforts => less is better
      final otherRouteDiscomforts = (await discomforts.getDiscomfortsForRoute(route)).length;
      if (otherRouteDiscomforts <= numDiscomforts) hasBestAttribute["numDiscomforts"] = false;
      if (secondBest["numDiscomforts"] == null ||
          secondBest["numDiscomforts"]!.$1 == null ||
          otherRouteDiscomforts < secondBest["numDiscomforts"]!.$2) {
        secondBest["numDiscomforts"] = (otherRoute, otherRouteDiscomforts.toDouble());
      }

      // Number PushBike => less is better
      if (otherRoute.path.details.getOffBike.length <= numPushBike) hasBestAttribute["numPushBike"] = false;
      if (secondBest["numPushBike"] == null ||
          secondBest["numPushBike"]!.$1 == null ||
          otherRoute.path.details.getOffBike.length < secondBest["numPushBike"]!.$2) {
        secondBest["numPushBike"] = (otherRoute, otherRoute.path.details.getOffBike.length.toDouble());
      }

      // Earliest Arrival => less is better
      if (otherRoute.path.time <= arrivalTime) hasBestAttribute["earliestArrival"] = false;
      if (secondBest["earliestArrival"] == null ||
          secondBest["earliestArrival"]!.$1 == null ||
          otherRoute.path.time < secondBest["earliestArrival"]!.$2) {
        secondBest["earliestArrival"] = (otherRoute, otherRoute.path.time.toDouble());
      }

      // Route length => less is better
      if (otherRoute.path.distance <= distance) hasBestAttribute["shortest"] = false;
      if (secondBest["shortest"] == null ||
          secondBest["shortest"]!.$1 == null ||
          otherRoute.path.distance < secondBest["shortest"]!.$2) {
        secondBest["shortest"] = (otherRoute, otherRoute.path.distance);
      }
    }

    if (hasBestAttribute["numOkSGs"]!) {
      final difference = (numOkSGs / secondBest["numOkSGs"]!.$2 - 1) * 100;
      if (difference > thresholdNumOkSGsInPtc) return "Mehr verbundene\nAmpeln";
    }

    if (hasBestAttribute["numCrossings"]!) {
      final difference = (secondBest["numCrossings"]!.$2 / numCrossings - 1) * 100;
      if (difference > thresholdCrossingsInPtc) return "Weniger\nKreuzungen";
    }

    if (hasBestAttribute["numDiscomforts"]!) {
      final difference = (secondBest["numDiscomforts"]!.$2 / numDiscomforts - 1) * 100;
      if (difference > thresholdDiscomfortsInPtc) return "Angenehmere\nStrecke";
    }

    if (hasBestAttribute["numPushBike"]!) {
      final difference = secondBest["numPushBike"]!.$2 - numPushBike; // absolute difference
      if (difference > thresholdPushBikeAbsolute) return "Weniger\nAbsteigen";
    }

    if (hasBestAttribute["earliestArrival"]!) {
      final difference = (secondBest["earliestArrival"]!.$2 / arrivalTime - 1) * 100;
      if (difference > thresholdTimeInPtc) return "Schnellere\nAnkunftszeit";
    }

    if (hasBestAttribute["shortest"]!) {
      final difference = (secondBest["shortest"]!.$2 / distance - 1) * 100;
      if (difference > thresholdDistanceInPtc) return "Kürzere\nStrecke";
    }

    // Route is in every aspect worse than all other routes
    return null;
  }
}
