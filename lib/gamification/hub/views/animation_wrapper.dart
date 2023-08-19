import 'dart:math';

import 'package:flutter/material.dart';

/// Wrapper class for elements on the game hub which should appear with a sliding animation from the right side.
class GameHubAnimationWrapper extends StatelessWidget {
  /// Controller which controls the element animation.
  final AnimationController controller;

  /// Content to be displayed inside of the element card.
  final Widget child;

  /// Start and end of the animation interval.
  final double start, end;

  const GameHubAnimationWrapper(
      {Key? key, required this.controller, required this.child, required this.start, required this.end})
      : super(key: key);

  /// Animation which lets the element slide in from the left of the screen.
  Animation<Offset> get _animation => Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(min(start, 1.0), min(end, 1.0), curve: Curves.easeIn),
      ));

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: child,
    );
  }
}
