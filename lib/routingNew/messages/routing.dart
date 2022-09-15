import 'package:priobike/common/models/point.dart';
import 'package:priobike/routing/models/route.dart' as r;
import 'package:priobike/routing/models/waypoint.dart';

class RouteRequest {
  /// The selected waypoints.
  final List<Point>? waypoints;

  const RouteRequest({required this.waypoints});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (waypoints != null) data['waypoints'] = waypoints?.map((v) => v.toJson()).toList();
    return data;
  }
}

class RoutesResponse {
  /// The list of routes.
  final List<r.Route> routes;

  RoutesResponse({required this.routes});

  factory RoutesResponse.fromJson(Map<String, dynamic> json) {
    return RoutesResponse(
      routes: (json['routes'] as List).map((e) => r.Route.fromJson(e)).toList(),
    );
  }

  /// The routes response, connected to the start and end point.
  RoutesResponse connected(Waypoint startpoint, Waypoint endpoint) {
    return RoutesResponse(
      routes: routes.map((e) => e.connected(startpoint, endpoint)).toList(),
    );
  }
}
