import 'package:priobike/models/api/api_point.dart';
import 'package:priobike/models/api/api_sg.dart';

class ApiRoute {
  String status;
  double distance;
  int time;
  double ascend;
  double descend;
  List<ApiSg> signalgroups;
  List<ApiPoint> route;

  ApiRoute({
    this.status,
    this.distance,
    this.time,
    this.ascend,
    this.descend,
    this.route,
    this.signalgroups,
  });

  ApiRoute.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    distance = json['distance'].toDouble();
    time = json['time'];
    ascend = json['ascend'].toDouble();
    descend = json['descend'].toDouble();
    if (json['route'] != null) {
      route = new List<ApiPoint>.empty(growable: true);
      json['route'].forEach((v) {
        route.add(new ApiPoint.fromJson(v));
      });
    }
    if (json['signalgroups'] != null) {
      signalgroups = new List<ApiSg>.empty(growable: true);
      json['signalgroups'].forEach((v) {
        signalgroups.add(new ApiSg.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['distance'] = this.distance;
    data['time'] = this.time;
    data['ascend'] = this.ascend;
    data['descend'] = this.descend;
    if (this.route != null) {
      data['route'] = this.route.map((v) => v.toJson()).toList();
    }
    if (this.signalgroups != null) {
      data['signalgroups'] = this.signalgroups.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
