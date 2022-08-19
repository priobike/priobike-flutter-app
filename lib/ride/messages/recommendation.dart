import 'dart:convert';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:priobike/common/models/point.dart';

class Recommendation {
  String label = "";
  int countdown = 0;
  double distance = 0;
  double speedRec = 0;
  double speedDiff = 0;
  bool green = false;
  bool error = false;
  String errorMessage = "";
  Point snapPos = const Point(lon: 0, lat: 0);
  String navText = "";
  int navSign = 0;
  double navDist = 0;
  double quality = 0;

  int? predictionGreentimeThreshold;
  String? predictionStartTime;
  List<int>? predictionValue;

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
    required this.navText,
    required this.navSign,
    required this.navDist,
    required this.quality,
    required this.predictionGreentimeThreshold,
    required this.predictionStartTime,
    required this.predictionValue,
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
    navText = json['navText'];
    navSign = json['navSign'];
    navDist = json['navDist'];
    navDist = json['quality'];
    predictionGreentimeThreshold = json['predictionGreentimeThreshold'];
    predictionStartTime = json['predictionStartTime'];
    predictionValue = json['predictionValue'].cast<int>();
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

    try {
      navText = params['navText'].asStringOr('');
    } catch (error) {
      // do nothing and use empty string
    }

    navSign = params['navSign'].asInt;
    navDist = params['navDist'].asNum as double;

    try {
      quality = params['quality'].asNum as double;
    } catch (error) {
      // do nothing and use empty string
    }

    // Unwrap optional values for prediction
    try {
      predictionGreentimeThreshold = params['predictionGreentimeThreshold'].asNum as int;
      predictionStartTime = params['predictionStartTime'].asString;
      predictionValue = params['predictionValue'].asList.cast<num>().map((e) => e.toInt()).toList();
    } catch (error) { 
      // ignore: avoid_print
      print(error);
    }
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
    data['navText'] = navText;
    data['navSign'] = navSign;
    data['navDist'] = navDist;
    data['quality'] = quality;
    data['predictionGreentimeThreshold'] = predictionGreentimeThreshold;
    data['predictionStartTime'] = predictionStartTime;
    data['predictionValue'] = predictionValue;
    JsonEncoder encoder = const JsonEncoder();
    return encoder.convert(data);
  }
}
