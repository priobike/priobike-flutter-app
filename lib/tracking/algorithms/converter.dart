import 'package:latlong2/latlong.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/models/waypoint.dart';

/// Converts a dense list of navigation nodes to a list of waypoints that are essential to generate a route.
List<Waypoint> convertNodesToWaypoints(List<NavigationNode> nodes, Distance vincenty) {
  List<dynamic> waypoints = List.generate(nodes.length, (index) {
    final routeNode = nodes[index];

    // Add first and last waypoint.
    if (index == 0 || index == nodes.length - 1) {
      return Waypoint(
        routeNode.lat,
        routeNode.lon,
        address: "Wegpunkt",
      );
    }

    // Add those where the direction of the route changes significantly.
    // This is to avoid too many waypoints.
    const directionThreshold = 50.0;
    if (index > 1) {
      final previousRouteNode = nodes[index - 1];
      final previousPreviousRouteNode = nodes[index - 2];
      final direction = vincenty.bearing(
        LatLng(previousRouteNode.lat, previousRouteNode.lon),
        LatLng(routeNode.lat, routeNode.lon),
      );
      final previousDirection = vincenty.bearing(
        LatLng(previousPreviousRouteNode.lat, previousPreviousRouteNode.lon),
        LatLng(previousRouteNode.lat, previousRouteNode.lon),
      );
      final directionDifference = (direction - previousDirection).abs();
      if (directionDifference > directionThreshold) {
        return Waypoint(
          routeNode.lat,
          routeNode.lon,
          address: "Wegpunkt",
        );
      }
    }

    // Also add those were the distance to the previous waypoint is greater than a threshold.
    const distanceThreshold = 500.0;
    if (index > 0) {
      final previousRouteNode = nodes[index - 1];
      final distance = vincenty.distance(
        LatLng(previousRouteNode.lat, previousRouteNode.lon),
        LatLng(routeNode.lat, routeNode.lon),
      );
      if (distance > distanceThreshold) {
        return Waypoint(
          routeNode.lat,
          routeNode.lon,
          address: "Wegpunkt",
        );
      }
    }

    return null;
  });

  // Remove null values from the list.
  List<Waypoint> filteredWaypoints = [];
  for (var waypoint in waypoints) {
    if (waypoint != null) {
      filteredWaypoints.add(waypoint);
    }
  }

  return filteredWaypoints;
}

/// Converts a duration to a human readable string.
String formatDuration(Duration duration) {
  final seconds = duration.inSeconds;
  if (seconds < 60) {
    return "${seconds.toStringAsFixed(0)} Sekunden";
  }
  if (seconds < 3600) {
    final minutes = seconds / 60;
    return "${minutes.toStringAsFixed(2)} Minuten";
  }
  final hours = seconds / 3600;
  return "${hours.toStringAsFixed(2)} Stunden";
}

/// Converts routes (initial + reroute-routes) to a list of navigation nodes that were actually passed.
List<NavigationNode> getPassedNodes(List<Route> routes, Distance vincenty) {
  List<NavigationNode> drivenRoute = [];

  // Find reroute locations
  List<int> rerouteNodeIndices = [];
  if (routes.length > 1) {
    for (var routeIdx = 0; routeIdx < routes.length; routeIdx++) {
      if (routeIdx >= routes.length - 1) {
        // If it's the last route, we can stop here.
        break;
      }
      final navigationNodes = routes.toList()[routeIdx].route;
      final nextRoutesFirstNavigationNode = routes.toList()[routeIdx + 1].route[0];

      // Find the navigation node that is closest to the first navigation node of the next route.
      var currentShortestDistance = double.infinity;
      var currentShortestDistanceIdx = -1;
      for (var navigationNodeIdx = 0; navigationNodeIdx < navigationNodes.length; navigationNodeIdx++) {
        final distance = vincenty.distance(
          LatLng(navigationNodes[navigationNodeIdx].lat, navigationNodes[navigationNodeIdx].lon),
          LatLng(nextRoutesFirstNavigationNode.lat, nextRoutesFirstNavigationNode.lon),
        );
        if (distance < currentShortestDistance) {
          currentShortestDistance = distance;
          currentShortestDistanceIdx = navigationNodeIdx;
        }
      }

      // The navigation node that is closest to the first navigation node of the next route is the reroute location.
      rerouteNodeIndices.add(currentShortestDistanceIdx);
    }
  }

  // Add points until the index of the reroute location is reached.
  for (var routeIdx = 0; routeIdx < routes.length; routeIdx++) {
    final navigationNodes = routes.toList()[routeIdx].route;
    for (var navigationNodeIdx = 0; navigationNodeIdx < navigationNodes.length; navigationNodeIdx++) {
      // If it's the last route, add all navigation nodes
      if (routeIdx >= routes.length - 1) {
        drivenRoute.add(navigationNodes[navigationNodeIdx]);
      } else {
        if (navigationNodeIdx == rerouteNodeIndices[routeIdx]) {
          // Go to next route.
          break;
        }
        drivenRoute.add(navigationNodes[navigationNodeIdx]);
      }
    }
  }

  return drivenRoute;
}
