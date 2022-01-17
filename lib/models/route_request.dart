import 'package:priobike/models/point.dart';

class RouteRequest {
  String? sessionId;
  List<Point>? waypoints;

  RouteRequest({required this.sessionId, required this.waypoints});

  RouteRequest.fromJson(Map<String, dynamic> json) {
    sessionId = json['sessionId'];
    if (json['waypoints'] != null) {
      waypoints = <Point>[];
      json['waypoints'].forEach((v) {
        waypoints?.add(Point.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sessionId'] = sessionId;
    if (waypoints != null) {
      data['waypoints'] = waypoints?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
