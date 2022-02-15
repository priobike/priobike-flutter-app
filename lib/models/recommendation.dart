import 'dart:convert';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:priobike/models/point.dart';

class Recommendation {
  String label = "";
  int countdown = 0;
  double distance = 0;
  double speedRec = 0;
  double speedDiff = 0;
  bool green = false;
  bool error = false;
  String errorMessage = "";
  Point snapPos = Point(lon: 0, lat: 0);

  Recommendation({
    required this.label,
    required this.countdown,
    required this.distance,
    required this.speedRec,
    required this.speedDiff,
    required this.green,
    required this.error,
    required this.errorMessage,
    required this.snapPos,
  });

  Recommendation.fromJson(Map<String, dynamic> json) {
    label = json['label'];
    countdown = json['countdown'];
    distance = json['distance'].toDouble();
    speedRec = json['speedRec'].toDouble();
    speedDiff = json['speedDiff'].toDouble();
    green = json['green'];
    error = json['error'];
    errorMessage = json['errorMessage'];
    snapPos = Point.fromJson(json['snapPos']);
  }

  Recommendation.fromJsonRPC(Parameters params) {
    label = params['label'].asStringOr('Unbekannt');
    countdown = params['countdown'].asInt;
    distance = params['distance'].asNumOr(0.0) as double;
    green = params['green'].asBoolOr(false);
    speedRec = params['speedRec'].asNumOr(0.0) as double;
    speedDiff = params['speedDiff'].asNumOr(0.0) as double;
    error = params['error'].asBoolOr(true);
    errorMessage = params['errorMessage'].asStringOr('Empfehlung fehlerhaft');
    snapPos = Point.fromJson(params['snapPos'].value);
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
    data['snapPos'] = snapPos.toJson();
    JsonEncoder encoder = const JsonEncoder.withIndent('    ');
    return encoder.convert(data);
  }
}
