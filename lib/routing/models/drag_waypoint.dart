import 'package:priobike/routing/models/waypoint.dart';

/// The type of a waypoint that is being dragged by user.
enum WaypointType {
  start,
  destination,
  waypoint,
}

/// The icon path of a waypoint type.
extension IconPath on WaypointType {
  String get iconPath {
    switch (this) {
      case WaypointType.start:
        return 'assets/images/start.drawio.png';
      case WaypointType.destination:
        return 'assets/images/destination.drawio.png';
      case WaypointType.waypoint:
        return 'assets/images/waypoint.drawio.png';
    }
  }
}

/// Determines whether the waypoint is a start, destination or waypoint in between.
WaypointType getWaypointType(List<Waypoint> list, Waypoint waypoint) {
  if (list.last == waypoint) {
    return WaypointType.destination;
  } else if (list.first == waypoint) {
    return WaypointType.start;
  } else {
    return WaypointType.waypoint;
  }
}
