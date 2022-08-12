import 'dart:math';

import 'package:flutter/material.dart';

/// An icon that is displayed centered over the map to show the user position.
class PositionIcon extends Container {
  /// Create a new position icon.
  PositionIcon({Key? key}) : super(key: key, 
    child: Stack(alignment: Alignment.center, children: const [
      Icon(
        Icons.navigation,
        color: Color.fromARGB(255, 0, 0, 0),
        size: 64,
      ),
      Icon(
        Icons.navigation,
        color: Color.fromARGB(255, 0, 149, 255),
        size: 48,
      ),
      Icon(
        Icons.circle_outlined,
        color: Color.fromARGB(25, 0, 0, 0),
        size: 108,
      ),
    ]),
    transform: Matrix4.translationValues(0.0, 28, 0.0) * Matrix4.rotationX(0.2 * pi),
  );
}