import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';

/// Custom level colors with at least a 3:1 contrast on white and black.
class LevelColors {
  static Color grey = Colors.grey;
  static const Color pink = Color.fromRGBO(238, 0, 136, 1); //ee0088 | onWhite: 4.2:1 - onBlack: 4.99:1
  static const Color green = Color.fromRGBO(17, 147, 0, 1); //119300 | onWhite: 4.04:1 - onBlack: 5.19:1
  static const Color gold = Color.fromRGBO(177, 144, 37, 1); //d4af37 | onWhite: 3.04:1 - onBlack: 6.88:1
  static const Color silver = Color.fromRGBO(122, 125, 144, 1); //7A7D90 | onWhite: 4.06:1 - onBlack: 5.16:1
  static const Color bronze = Color.fromRGBO(169, 113, 66, 1); //a97142 | onWhite: 4.09:1 - onBlack: 5.12:1
  static const Color diamond = Color.fromRGBO(0, 156, 235, 1); //009CEB | onWhite: 3.01:1 - onBlack: 6.95:1
  static const Color priobike = CI.blue; //0073ff | onWhite: 4.28:1 - onBlack: 4.89:1

  /// Get a color in a slightly lighter tone.
  static Color brighten(Color color) => HSLColor.fromColor(color).withLightness(0.58).toColor();
}
