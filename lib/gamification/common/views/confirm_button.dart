import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/on_tap_animation.dart';

class ConfirmButton extends StatelessWidget {
  final String label;

  final Function()? onPressed;

  const ConfirmButton({Key? key, required this.label, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OnTapAnimation(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: onPressed == null ? Theme.of(context).colorScheme.onBackground.withOpacity(0.25) : CI.blue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onBackground,
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
