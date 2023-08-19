import 'package:flutter/material.dart';

class LongDuration extends Duration {
  LongDuration() : super(milliseconds: 1000);
}

class ShortDuration extends Duration {
  ShortDuration() : super(milliseconds: 500);
}

/// Simple fade tranistion to animate widgets.
class CustomFadeTransition extends FadeTransition {
  CustomFadeTransition({Key? key, required AnimationController controller, required Widget child, Interval? interval})
      : super(key: key, opacity: getFadeAnimation(controller, interval), child: child);

  static Animation<double> getFadeAnimation(var controller, var interval) => CurvedAnimation(
        parent: controller,
        curve: interval ?? const Interval(0, 1, curve: Curves.easeIn),
      );
}
