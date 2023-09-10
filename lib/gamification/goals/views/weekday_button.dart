import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';

class WeekdayButton extends StatefulWidget {
  final String label;

  final Function()? onPressed;

  final bool selected;

  const WeekdayButton({Key? key, required this.label, required this.onPressed, required this.selected})
      : super(key: key);

  @override
  State<WeekdayButton> createState() => _WeekdayButtonState();
}

class _WeekdayButtonState extends State<WeekdayButton> with SingleTickerProviderStateMixin {
  bool get disable => widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      scaleFactor: 0.85,
      blockFastClicking: false,
      onPressed: widget.onPressed,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              widget.selected ? CI.blue : Theme.of(context).colorScheme.onBackground.withOpacity(disable ? 0.05 : 0.1),
        ),
        child: Center(
          child: BoldSmall(
            text: widget.label,
            context: context,
            color: widget.selected
                ? Colors.white
                : Theme.of(context).colorScheme.onBackground.withOpacity(disable ? 0.25 : 1),
          ),
        ),
      ),
    );
  }
}
