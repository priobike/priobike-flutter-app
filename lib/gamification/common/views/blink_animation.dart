import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/utils.dart';

/// Creates a continous blink animation for the child widget by chaning its scale.
class BlinkAnimation extends StatefulWidget {
  /// The widget to get blinking.
  final Widget child;

  /// The max scale the widget should have when blinking.
  final double scaleFactor;

  /// Whether the blinking should be active.
  final bool animate;

  /// Duration of one scale animation.
  final Duration duration;

  const BlinkAnimation({
    super.key,
    required this.child,
    this.scaleFactor = 1.3,
    this.animate = true,
    this.duration = const MediumDuration(),
  });

  @override
  State<BlinkAnimation> createState() => _BlinkAnimationState();
}

class _BlinkAnimationState extends State<BlinkAnimation> with SingleTickerProviderStateMixin {
  /// Animation controller to control the blinking animation.
  late final AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: widget.duration, value: 1);
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Start or stop the blinking animation according to the animate bool.
    if (widget.animate) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
    }
    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: widget.scaleFactor).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ),
      ),
      child: widget.child,
    );
  }
}
