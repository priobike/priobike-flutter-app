import 'dart:convert';

import 'package:json_rpc_2/json_rpc_2.dart';

class Recommendation {
  String label;
  int countdown;
  double distance;
  double speedRec;
  double speedDiff;
  bool isGreen;
  bool error;
  String errorMessage;

  Recommendation(
      {this.label,
      this.countdown,
      this.distance,
      this.speedRec,
      this.speedDiff,
      this.isGreen,
      this.error,
      this.errorMessage});

  Recommendation.fromJson(Map<String, dynamic> json) {
    label = json['label'];
    countdown = json['countdown'];
    distance = json['distance'].toDouble();
    speedRec = json['speedRec'].toDouble();
    speedDiff = json['speedDiff'].toDouble();
    isGreen = json['isGreen'];
    error = json['error'];
    errorMessage = json['errorMessage'];
  }

  Recommendation.fromJsonRPC(Parameters params) {
    label = params['label'].asString;
    countdown = params['countdown'].asNum;
    distance = params['distance'].asNum;
    isGreen = params['isGreen'].asBool;
    speedRec = params['speedRec'].asNum;
    speedDiff = params['speedDiff'].asNum;
    error = params['error'].asBool;
    errorMessage = params['errorMessage'].asString;
  }

  String toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['label'] = this.label;
    data['countdown'] = this.countdown;
    data['distance'] = this.distance;
    data['speedRec'] = this.speedRec;
    data['speedDiff'] = this.speedDiff;
    data['isGreen'] = this.isGreen;
    data['error'] = this.error;
    data['errorMessage'] = this.errorMessage;
    return json.encode(data);
  }
}
