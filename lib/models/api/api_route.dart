import 'package:bikenow/models/api/api_point.dart';
import 'package:bikenow/models/api/api_sg.dart';

class ApiRoute {
  String status;
  double distance;
  int time;
  double ascend;
  double descend;
  List<ApiSg> sg;
  List<ApiPoint> points;

  ApiRoute({
    this.status,
    this.distance,
    this.time,
    this.ascend,
    this.descend,
    this.points,
    this.sg,
  });

  ApiRoute.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    distance = json['distance'];
    time = json['time'];
    ascend = json['ascend'];
    descend = json['descend'];
    if (json['points'] != null) {
      points = new List<ApiPoint>();
      json['points'].forEach((v) {
        points.add(new ApiPoint.fromJson(v));
      });
    }
    if (json['sg'] != null) {
      sg = new List<ApiSg>();
      json['sg'].forEach((v) {
        sg.add(new ApiSg.fromJson(v));
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
    if (this.points != null) {
      data['points'] = this.points.map((v) => v.toJson()).toList();
    }
    if (this.sg != null) {
      data['sg'] = this.sg.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
