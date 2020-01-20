import 'package:bikenow/models/route.dart';
import 'package:bikenow/models/sg.dart';

class RouteAnswer {
  String status;
  double distance;
  int time;
  int ascend;
  int descend;
  List<Route> route;
  List<Sg> sg;

  RouteAnswer(
      {this.status,
      this.distance,
      this.time,
      this.ascend,
      this.descend,
      this.route,
      this.sg});

  RouteAnswer.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    distance = json['distance'];
    time = json['time'];
    ascend = json['ascend'];
    descend = json['descend'];
    if (json['route'] != null) {
      route = new List<Route>();
      json['route'].forEach((v) {
        route.add(new Route.fromJson(v));
      });
    }
    if (json['sg'] != null) {
      sg = new List<Sg>();
      json['sg'].forEach((v) {
        sg.add(new Sg.fromJson(v));
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
    if (this.sg != null) {
      data['sg'] = this.sg.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
