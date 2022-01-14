import 'package:priobike/models/point.dart';

class RouteRequest {
  String? sessionId;
  Point? from;
  Point? to;

  RouteRequest({required this.sessionId, required this.from, required this.to});

  RouteRequest.fromJson(Map<String, dynamic> json) {
    sessionId = json['sessionId'];
    from = Point.fromJson(json['from']);
    to = Point.fromJson(json['to']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sessionId'] = sessionId;
    data['from'] = from!.toJson();
    data['to'] = to!.toJson();
    return data;
  }
}
