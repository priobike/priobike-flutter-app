import 'package:priobike/common/models/point.dart';

class RouteRequest {
  /// The selected waypoints.
  final List<Point>? waypoints;

  const RouteRequest({required this.waypoints});

  Map<String, dynamic> toJson() => {
        if (waypoints != null) 'waypoints': waypoints?.map((v) => v.toJson()).toList(),
      };
}
