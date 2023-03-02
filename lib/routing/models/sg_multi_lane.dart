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

  const SgMultiLane({
    required this.id,
    required this.position,
    required this.projectedLengthOnRoute,
    required this.bearingStart,
    required this.bearingEnd,
    required this.distanceOnRoute,
    required this.direction,
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
    return SgMultiLane(
      id: json['id'],
      position: Point.fromJson(json['position']),
      projectedLengthOnRoute: json['projectedLengthOnRoute'],
      bearingStart: json['bearingStart'],
      bearingEnd: json['bearingEnd'],
      distanceOnRoute: json['distanceOnRoute'],
      direction: direction,
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
      };
}

enum Direction {
  lightLeft,
  hardLeft,
  straight,
  lightRight,
  hardRight,
}
