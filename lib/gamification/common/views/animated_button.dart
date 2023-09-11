import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A child wrapped by this widget is animated and gives haptic feedback when pressed, if the callback is not null.
class OnTabAnimation extends StatefulWidget {
  /// The child wrapped by this widget.
  final Widget child;

  /// The callback function for when the widget is pressed.
  final Function()? onPressed;

  /// The scale factor with which the animation should happen.
  final double scaleFactor;

  /// Whether the widget should register a new click, while it is animating.
  final bool blockFastClicking;

  const OnTabAnimation({
    Key? key,
    required this.child,
    this.onPressed,
    this.scaleFactor = 0.9,
    this.blockFastClicking = true,
  }) : super(key: key);

  @override
  State<OnTabAnimation> createState() => _OnTabAnimationState();
}

class _OnTabAnimationState extends State<OnTabAnimation> with SingleTickerProviderStateMixin {
  /// Controller which controls the on pressed scale animation of the widget.
  late final AnimationController _animationController;

  /// True, if clicks on the widget should be blocked.
  bool _blocked = false;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.blockFastClicking ? 50 : 0),
      reverseDuration: const Duration(milliseconds: 150),
    );
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onPressed == null) return widget.child;
    return GestureDetector(
      onTapDown: (_) {
        if (widget.blockFastClicking && _animationController.isAnimating) return;
        HapticFeedback.heavyImpact();
        _animationController.forward();
      },
      onTapUp: (_) async {
        if (widget.blockFastClicking) {
          if (_blocked) return;
          _blocked = true;
          if (_animationController.isAnimating) await _animationController.forward();
          await _animationController.reverse();
          _blocked = false;
        } else {
          _animationController.reverse();
        }
        if (widget.onPressed != null) widget.onPressed!();
      },
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 1,
          end: widget.scaleFactor,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeIn,
        )),
        child: widget.child,
      ),
    );
  }
}
