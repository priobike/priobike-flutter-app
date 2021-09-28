import 'package:priobike/models/point.dart';
import 'package:priobike/models/sg.dart';

class RouteResponse {
  String? status;
  double? distance;
  int? time;
  double? ascend;
  double? descend;
  List<Sg>? signalgroups;
  List<Point>? route;

  RouteResponse({
    this.status,
    this.distance,
    this.time,
    this.ascend,
    this.descend,
    this.route,
    this.signalgroups,
  });

  RouteResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    distance = json['distance'].toDouble();
    time = json['time'];
    ascend = json['ascend'].toDouble();
    descend = json['descend'].toDouble();
    if (json['route'] != null) {
      route = List<Point>.empty(growable: true);
      json['route'].forEach((v) {
        route!.add(Point.fromJson(v));
      });
    }
    if (json['signalgroups'] != null) {
      signalgroups = List<Sg>.empty(growable: true);
      json['signalgroups'].forEach((v) {
        signalgroups!.add(Sg.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['distance'] = distance;
    data['time'] = time;
    data['ascend'] = ascend;
    data['descend'] = descend;
    if (route != null) {
      data['route'] = route!.map((v) => v.toJson()).toList();
    }
    if (signalgroups != null) {
      data['signalgroups'] = signalgroups!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
