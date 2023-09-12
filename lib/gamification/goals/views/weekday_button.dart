import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';

/// Button to describe a weekday to activate or deactive goals on this weekday.
class WeekdayButton extends StatelessWidget {
  /// Index of the day of week from 1 to 7.
  final int day;

  /// Callback for when the button is pressed.
  final Function()? onPressed;

  /// Whether the weekday is currently selected, which means it is displayed in blue.
  final bool selected;

  const WeekdayButton({Key? key, required this.day, required this.onPressed, required this.selected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool disable = onPressed == null;
    return OnTabAnimation(
      scaleFactor: 0.85,
      onPressed: onPressed,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? CI.blue : Theme.of(context).colorScheme.onBackground.withOpacity(disable ? 0.05 : 0.1),
        ),
        child: Center(
          child: BoldSmall(
            text: StringFormatter.getWeekStr(day),
            context: context,
            color: selected ? Colors.white : Theme.of(context).colorScheme.onBackground.withOpacity(disable ? 0.25 : 1),
          ),
        ),
      ),
    );
  }
}
