import 'package:flutter/material.dart';
import 'package:priobike/common/models/point.dart';

class SgMultiLane {
  /// The id of the signal group.
  final String id;

  /// The position of the signal group.
  final Point position;

  /// The projected length of the signal group on the route (in meter).
  final double projectedLengthOnRoute;

  /// The bearing of the start of the signal group.
  final double bearingStart;

  /// The bearing of the end of the signal group.
  final double bearingEnd;

  /// The distance of the SG on the route (in meter).
  final double distanceOnRoute;

  /// The direction of the signal group.
  final Direction direction;

  /// The lane type of the signal group (allowed vehicles).
  final LaneType laneType;

  SgMultiLane({
    required this.id,
    required this.position,
    required this.projectedLengthOnRoute,
    required this.bearingStart,
    required this.bearingEnd,
    required this.distanceOnRoute,
    required this.direction,
    required this.laneType,
  });

  factory SgMultiLane.fromJson(Map<String, dynamic> json) {
    Direction direction;
    if ((json["bearingEnd"] - json["bearingStart"]) % 360 < 10) {
      direction = Direction.straight;
    } else if ((json["bearingEnd"] - json["bearingStart"]) % 360 < 60) {
      direction = Direction.lightRight;
    } else if ((json["bearingEnd"] - json["bearingStart"]) % 360 < 180) {
      direction = Direction.hardRight;
    } else if ((json["bearingEnd"] - json["bearingStart"]) % 360 < 300) {
      direction = Direction.hardLeft;
    } else if ((json["bearingEnd"] - json["bearingStart"]) % 360 < 350) {
      direction = Direction.lightLeft;
    } else {
      direction = Direction.straight;
    }

    LaneType laneType;
    switch (json['laneType']) {
      case 'Radfahrer':
        laneType = LaneType.bike;
        break;
      case 'Fußgänger/Radfahrer':
        laneType = LaneType.bikePedestrian;
        break;
      case 'KFZ/Radfahrer':
        laneType = LaneType.bikeCar;
        break;
      case 'KFZ/Bus/Radfahrer':
        laneType = LaneType.bikeCarBus;
        break;
      case 'Bus/Radfahrer':
        laneType = LaneType.bikeBus;
        break;
      default:
        laneType = LaneType.unknown;
        break;
    }

    return SgMultiLane(
      id: json['id'],
      position: Point.fromJson(json['position']),
      projectedLengthOnRoute: json['projectedLengthOnRoute'],
      bearingStart: json['bearingStart'],
      bearingEnd: json['bearingEnd'],
      distanceOnRoute: json['distanceOnRoute'],
      direction: direction,
      laneType: laneType,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'position': position.toJson(),
        'projectedLengthOnRoute': projectedLengthOnRoute,
        'bearingStart': bearingStart,
        'bearingEnd': bearingEnd,
        'distanceOnRoute': distanceOnRoute,
        'direction': direction.name,
        'laneType': laneType.name,
      };
}

/// The direction of the signal group. Order matters, because by that it is sorted
enum Direction {
  hardLeft,
  lightLeft,
  straight,
  lightRight,
  hardRight,
}

extension DirectionComparion on Direction {
  int compareTo(Direction other) => index.compareTo(other.index);
}

extension DirectionIcon on Direction {
  IconData get icon {
    switch (this) {
      case Direction.hardLeft:
        return Icons.west;
      case Direction.lightLeft:
        return Icons.north_west;
      case Direction.straight:
        return Icons.north;
      case Direction.lightRight:
        return Icons.north_east;
      case Direction.hardRight:
        return Icons.east;
    }
  }
}

/// The lane type of the signal group (allowed vehicles).
enum LaneType {
  bike,
  bikePedestrian,
  bikeCar,
  bikeCarBus,
  bikeBus,
  unknown,
}

Widget _getCombinedIcons(Color iconColor, List<IconData> icons) {
  switch (icons.length) {
    case 1:
      return Icon(Icons.pedal_bike_rounded, color: iconColor, size: 28);
    case 2:
      return SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(icons[0], color: iconColor, size: 18),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Icon(icons[1], color: iconColor, size: 18),
            ),
          ],
        ),
      );
    case 3:
      return SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(icons[0], color: iconColor, size: 14),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Icon(icons[1], color: iconColor, size: 14),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Icon(icons[2], color: iconColor, size: 14),
            ),
          ],
        ),
      );
  }
  return const SizedBox();
}

extension LaneTypeIcon on LaneType {
  Widget icon(Color color) {
    switch (this) {
      case LaneType.bike:
        return _getCombinedIcons(color, [Icons.pedal_bike_rounded]);
      case LaneType.bikePedestrian:
        return _getCombinedIcons(color, [Icons.pedal_bike_rounded, Icons.directions_walk_rounded]);
      case LaneType.bikeCar:
        return _getCombinedIcons(color, [Icons.pedal_bike_rounded, Icons.directions_car_filled]);
      case LaneType.bikeCarBus:
        return _getCombinedIcons(
            color, [Icons.pedal_bike_rounded, Icons.directions_car_filled, Icons.directions_bus_filled]);
      case LaneType.bikeBus:
        return _getCombinedIcons(color, [Icons.pedal_bike_rounded, Icons.directions_bus_filled]);
      case LaneType.unknown:
        return _getCombinedIcons(color, []);
    }
  }
}
