import 'package:priobike/routing/models/waypoint.dart';

/// The type of a waypoint that is being dragged by user.
enum WaypointType {
  start,
  middle,
  destination,
}

/// The icon path of a waypoint type.
extension IconPath on WaypointType {
  String get iconPath {
    switch (this) {
      case WaypointType.start:
        return 'assets/images/start-noshadow.png';
      case WaypointType.middle:
        return 'assets/images/waypoint-noshadow.png';
      case WaypointType.destination:
        return 'assets/images/destination-noshadow.png';
    }
  }
}

/// Determines whether the waypoint is a start, destination or waypoint in between.
WaypointType getWaypointType(List<Waypoint> list, Waypoint waypoint) {
  if (!list.contains(waypoint)) throw Exception("Waypoint $waypoint is not in list $list.");

  if (list.last == waypoint) {
    return WaypointType.destination;
  } else if (list.first == waypoint) {
    return WaypointType.start;
  } else {
    return WaypointType.middle;
  }
}
