import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedButton extends StatefulWidget {
  final Widget child;

  final Function()? onPressed;

  final double scaleFactor;

  final bool blockFastClicking;

  const AnimatedButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.scaleFactor = 0.9,
    this.blockFastClicking = true,
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

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

  bool blocked = false;

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
          if (blocked) return;
          blocked = true;
          if (_animationController.isAnimating) await _animationController.forward();
          await _animationController.reverse();
          blocked = false;
        } else {
          _animationController.reverse();
        }
        if (widget.onPressed != null) widget.onPressed!();
      },
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: widget.scaleFactor)
            .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn)),
        child: widget.child,
      ),
    );
  }
}
