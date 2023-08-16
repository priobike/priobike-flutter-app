import 'dart:math';

import 'package:flutter/material.dart';

/// Wrapper class for the elements shown in a list in the gamification hub view. Handles the animation with which the
/// elements appear when opening the view and provides a uniformly styled card, in which the element content can
/// be placed.
class GamificationHubElement extends StatelessWidget {
  /// Controller which controls the element animation.
  final AnimationController controller;

  /// Content to be displayed inside of the element card.
  final Widget content;

  final double start, end;

  const GamificationHubElement(
      {Key? key, required this.controller, required this.content, required this.start, required this.end})
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
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.all(Radius.circular(24)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: content,
          ),
        ),
      ),
    );
  }
}
