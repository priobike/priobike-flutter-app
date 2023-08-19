import 'package:flutter/material.dart';

/// Fixed duration for a transition animation that should appear slow.
class LongTransitionDuration extends Duration {
  LongTransitionDuration() : super(milliseconds: 1000);
}

/// Fixed duration for a transition animation that should appear fast.
class ShortTransitionDuration extends Duration {
  ShortTransitionDuration() : super(milliseconds: 500);
}

/// Simple fade tranistion to let widgets appear smooth.
class CustomFadeTransition extends FadeTransition {
  CustomFadeTransition({Key? key, required AnimationController controller, required Widget child, Interval? interval})
      : super(key: key, opacity: getFadeAnimation(controller, interval), child: child);

  static Animation<double> getFadeAnimation(var controller, var interval) => CurvedAnimation(
        parent: controller,
        curve: interval ?? const Interval(0, 1, curve: Curves.easeIn),
      );
}
