import 'dart:convert';

import 'dart:typed_data';

import 'dart:ui';

import 'package:priobike/common/layout/ci.dart';

enum Phase {
  dark,
  red,
  amber,
  green,
  redAmber,
  amberFlashing,
  greenFlashing,
}

extension PhaseColor on Phase {
  static Phase fromInt(int i) {
    switch (i) {
      case 0:
        return Phase.dark;
      case 1:
        return Phase.red;
      case 2:
        return Phase.amber;
      case 3:
        return Phase.green;
      case 4:
        return Phase.redAmber;
      case 5:
        return Phase.amberFlashing;
      case 6:
        return Phase.greenFlashing;
      default:
        return Phase.dark;
    }
  }

  Color get color {
    switch (this) {
      case Phase.dark:
        return const Color(0xFF000000);
      case Phase.red:
        return CI.red;
      case Phase.amber:
        return const Color.fromARGB(255, 255, 251, 0);
      case Phase.green:
        // Don't use the CI green here.
        return const Color.fromARGB(255, 0, 255, 106);
      case Phase.redAmber:
        return const Color.fromARGB(255, 255, 251, 0);
      case Phase.amberFlashing:
        return const Color.fromARGB(255, 255, 251, 0);
      case Phase.greenFlashing:
        return const Color.fromARGB(255, 0, 255, 106);
    }
  }
}

class Prediction {
  /// The thing name of the signal.
  final String thingName;

  /// The prediction vector from the reference time ("now").
  final Uint8List now;

  /// The quality of the prediction vector from the reference time ("now").
  final Uint8List nowQuality;

  /// The prediction vector continuing "now".
  final Uint8List then;

  /// The quality of the prediction vector continuing "now".
  final Uint8List thenQuality;

  /// The reference time of the prediction.
  final DateTime referenceTime;

  /// The program ID of the prediction.
  final int? programId;

  /// Create a prediction from a JSON map.
  Prediction.fromJson(Map<String, dynamic> json)
      : thingName = json['thingName'] as String,
        now = base64Decode(json['now'] as String),
        nowQuality = base64Decode(json['nowQuality'] as String),
        then = base64Decode(json['then'] as String),
        thenQuality = base64Decode(json['thenQuality'] as String),
        referenceTime = DateTime.parse(json['referenceTime'] as String),
        programId = json['programId'] as int?;
}
