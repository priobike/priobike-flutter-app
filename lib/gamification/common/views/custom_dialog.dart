import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/utils.dart';

/// A dialog widget to be used with the showDialog function and which shows a dialog with given content in a uniform style.
class CustomDialog extends StatefulWidget {
  /// The content of the dialog widget.
  final Widget content;

  /// Background color of the dialog.
  final Color? backgroundColor;

  /// Whether to show a glow around the dialog.
  final bool withGlow;

  /// Margin on the right and left side of the dialog.
  final double horizontalMargin;

  const CustomDialog({
    Key? key,
    required this.content,
    this.backgroundColor,
    this.withGlow = false,
    this.horizontalMargin = 32,
  }) : super(key: key);

  @override
  State<CustomDialog> createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> with SingleTickerProviderStateMixin {
  /// Animation controller to animate the dialog appearing.
  late final AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: const MediumDuration());
    _animationController.forward();
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var lightmode = Theme.of(context).brightness == Brightness.light;
    return ScaleTransition(
      scale: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.fastLinearToSlowEaseIn,
        ),
      ),
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: widget.horizontalMargin),
          decoration: BoxDecoration(
            color: widget.backgroundColor ??
                (lightmode ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.background),
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            boxShadow: widget.withGlow
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(lightmode ? 1 : 0.25),
                      spreadRadius: 0,
                      blurRadius: 5,
                    ),
                  ]
                : null,
          ),
          child: widget.content,
        ),
      ),
    );
  }
}
