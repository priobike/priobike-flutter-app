import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/on_tap_animation.dart';

class ConfirmButton extends StatelessWidget {
  final String label;

  final Color color;

  final Function()? onPressed;

  const ConfirmButton({Key? key, required this.label, this.onPressed, this.color = CI.blue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OnTapAnimation(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        //width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onPressed == null ? Theme.of(context).colorScheme.onBackground.withOpacity(0.25) : color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
              blurRadius: 4,
              spreadRadius: 4,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: SubHeader(
          text: label,
          context: context,
          color: onPressed == null ? Theme.of(context).colorScheme.onBackground : Colors.white,
        ),
      ),
    );
  }
}
