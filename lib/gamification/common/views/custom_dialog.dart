import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/utils.dart';

class CustomDialog extends StatefulWidget {
  final Widget content;

  const CustomDialog({Key? key, required this.content}) : super(key: key);

  @override
  State<CustomDialog> createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> with SingleTickerProviderStateMixin {
  /// Animation controller to animate the dialog appearing.
  late final AnimationController _animationController;

  /// Animation to
  Animation<double> get animation => Tween<double>(begin: 0, end: 1)
      .animate(CurvedAnimation(parent: _animationController, curve: Curves.fastLinearToSlowEaseIn));

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: ShortDuration());
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
      scale: animation,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: lightmode ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(lightmode ? 1 : 0.25),
                spreadRadius: 0,
                blurRadius: 50,
              ),
            ],
          ),
          child: widget.content,
        ),
      ),
    );
  }
}