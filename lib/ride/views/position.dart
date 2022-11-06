import 'dart:math';

import 'package:flutter/material.dart';

/// An icon that is displayed centered over the map to show the user position.
class PositionIcon extends Container {
  /// Create a new position icon.
  PositionIcon({required Brightness brightness, Key? key})
      : super(
          key: key,
          child: Image.asset(
              brightness == Brightness.dark ? "assets/images/position-dark.png" : "assets/images/position-light.png",
              width: 128,
              height: 128,
              fit: BoxFit.contain),
          transform: Matrix4.translationValues(0.0, 28, 0.0) * Matrix4.rotationX(0.2 * pi),
        );
}
