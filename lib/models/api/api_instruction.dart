import 'package:bikenow/models/api/api_point.dart';

class ApiInstruction {
  double distance;
  double heading;
  int sign;
  String text;
  int time;
  String streetName;
  List<ApiPoint> points;
  String annotationText;
  double lastHeading;

  ApiInstruction(
      {this.distance,
      this.heading,
      this.sign,
      this.text,
      this.time,
      this.streetName,
      this.points,
      this.annotationText,
      this.lastHeading});

  ApiInstruction.fromJson(Map<String, dynamic> json) {
    distance = json['distance'].toDouble();
    heading = json['heading'];
    sign = json['sign'];
    text = json['text'];
    time = json['time'];
    streetName = json['street_name'];
    if (json['points'] != null) {
      points = new List<ApiPoint>();
      json['points'].forEach((v) {
        points.add(new ApiPoint.fromJson(v));
      });
    }
    annotationText = json['annotation_text'];
    lastHeading = json['last_heading'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['distance'] = this.distance;
    data['heading'] = this.heading;
    data['sign'] = this.sign;
    data['text'] = this.text;
    data['time'] = this.time;
    data['street_name'] = this.streetName;
    if (this.points != null) {
      data['points'] = this.points.map((v) => v.toJson()).toList();
    }
    data['annotation_text'] = this.annotationText;
    data['last_heading'] = this.lastHeading;
    return data;
  }
}
