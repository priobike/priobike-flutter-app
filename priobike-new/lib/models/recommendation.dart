import 'dart:convert';

import 'package:json_rpc_2/json_rpc_2.dart';

class Recommendation {
  String? label;
  int? countdown;
  double? distance;
  double? speedRec;
  double? speedDiff;
  bool? green;
  bool? error;
  String? errorMessage;

  Recommendation(
      {required this.label,
      required this.countdown,
      required this.distance,
      required this.speedRec,
      required this.speedDiff,
      required this.green,
      required this.error,
      required this.errorMessage});

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
    label = params['label'].asStringOr('Unbekannt');
    countdown = params['countdown'].asInt;
    distance = params['distance'].asNumOr(0.0) as double?;
    green = params['green'].asBoolOr(false);
    speedRec = params['speedRec'].asNumOr(0.0) as double?;
    speedDiff =params['speedDiff'].asNumOr(0.0) as double?;
    error = params['error'].asBoolOr(true);
    errorMessage = params['errorMessage'].asStringOr('Empfehlung fehlerhaft');
  }

  String toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['label'] = label;
    data['countdown'] = countdown;
    data['distance'] = distance;
    data['speedRec'] = speedRec;
    data['speedDiff'] = speedDiff;
    data['green'] = green;
    data['error'] = error;
    data['errorMessage'] = errorMessage;
    return json.encode(data);
  }
}
