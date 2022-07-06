
import 'package:flutter/material.dart';

/// A fade wrapper to fade out views at the bottom and top of the screen.
class Fade extends ShaderMask {
  Fade({Key? key, required Widget child}) : super(
    key: key, 
    shaderCallback: (Rect rect) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.purple, Colors.transparent, Colors.transparent, Colors.purple],
        stops: [0.0, 0.1, 0.7, 1.0],
      ).createShader(rect);
    },
    blendMode: BlendMode.dstOut, 
    child: child
  );
}