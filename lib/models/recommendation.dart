import 'dart:convert';

import 'package:json_rpc_2/json_rpc_2.dart';

class Recommendation {
  String label;
  int countdown;
  double distance;
  double speedRec;
  double speedDiff;
  bool green;
  bool error;
  String errorMessage;

  Recommendation(
      {this.label,
      this.countdown,
      this.distance,
      this.speedRec,
      this.speedDiff,
      this.green,
      this.error,
      this.errorMessage});

  Recommendation.fromJson(Map<String, dynamic> json) {
    label = json['label'];
    countdown = json['countdown'];
    distance = json['distance'].toDouble();
    speedRec = json['speedRec'].toDouble();
    speedDiff = json['speedDiff'].toDouble();
    green = json['green'];
    error = json['error'];
    errorMessage = json['errorMessage'];
  }

  Recommendation.fromJsonRPC(Parameters params) {
    print(params['label'].valueOr('No Value'));

    label = params['label'].value != null ? params['label'].asString : 'Fehler';
    countdown = params['countdown'].value != null ? params['countdown'].asNum : false;
    distance = params['distance'].value != null ? params['distance'].asNum : 0;
    green = params['green'].value != null ? params['green'].asBool : false;
    speedRec = params['speedRec'].value != null ? params['speedRec'].asNum : 0.0;
    speedDiff = params['speedDiff'].value != null? params['speedDiff'].asNum : 0.0;
    error = params['error'].value != null ? params['error'].asBool : true;
    errorMessage = params['errorMessage'].value != null ? params['errorMessage'].asString : 'Fehler';
  }

  String toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['label'] = this.label;
    data['countdown'] = this.countdown;
    data['distance'] = this.distance;
    data['speedRec'] = this.speedRec;
    data['speedDiff'] = this.speedDiff;
    data['green'] = this.green;
    data['error'] = this.error;
    data['errorMessage'] = this.errorMessage;
    return json.encode(data);
  }
}
