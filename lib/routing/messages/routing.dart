import 'package:priobike/common/models/point.dart';
import 'package:priobike/routing/messages/graphhopper/response.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/routing/models/sg.dart';

class RouteRequest {
  /// The session id for the session wrapper.
  final String? sessionId;

  /// The selected waypoints.
  final List<Point>? waypoints;

  const RouteRequest({required this.sessionId, required this.waypoints});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sessionId'] = sessionId;
    if (waypoints != null) data['waypoints'] = waypoints?.map((v) => v.toJson()).toList();
    return data;
  }
}

class RouteResponse {
  /// The selected signal groups along the route.
  final Map<String, Sg> signalgroups;

  /// The navigation nodes of the route.
  final List<NavigationNode> route;

  /// The first GraphHopper route response path from the `/route` endpoint.
  GHRouteResponsePath path;

  RouteResponse({
    required this.route,
    required this.signalgroups,
    required this.path,
  });

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    final signalgroups = <String, Sg>{};
    json['signalGroups'].values.forEach((entry) {
      Sg sg = Sg.fromJson(entry);
      signalgroups[sg.id] = sg;
    });

    return RouteResponse(
      signalgroups: signalgroups, 
      route: (json['route'] as List).map((e) => NavigationNode.fromJson(e)).toList(), 
      path: GHRouteResponsePath.fromJson(json['path'])
    );
  }
}
