import 'package:flutter/material.dart';

/// A fade wrapper to fade out views at the bottom and top of the screen.
class Fade extends ShaderMask {
  /// Custom stops of the fade.
  final List<double>? stops;

  Fade({super.key, required Widget super.child, this.stops})
      : super(
            shaderCallback: (Rect rect) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [Colors.purple, Colors.transparent, Colors.transparent, Colors.purple],
                stops: stops ?? [0.0, 0.05, 0.95, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstOut);
}
