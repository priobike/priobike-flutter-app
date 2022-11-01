import 'package:flutter/material.dart';

class BlendIn extends StatefulWidget {
  /// The easing curve of the animation.
  final Curve curve;

  /// The delay of the animation.
  final Duration delay;

  /// The duration of the animation.
  final Duration duration;

  /// The wrapped widget.
  final Widget child;

  const BlendIn({
    Key? key,
    this.curve = Curves.easeInOutCubic,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    required this.child,
  }) : super(key: key);

  @override
  BlendInState createState() => BlendInState();
}

class BlendInState extends State<BlendIn> with SingleTickerProviderStateMixin {
  /// The animation controller used to animate the opacity.
  late AnimationController controller;

  /// The animation used to animate the opacity.
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: widget.duration);
    animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: widget.curve),
    );
    // Run the animation with the delay.
    Future<void>.delayed(widget.delay, controller.forward);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: animation, child: widget.child);
  }
}