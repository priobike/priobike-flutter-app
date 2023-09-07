import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';

class GoalSettingSlider extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final double stepSize;
  final String valueLabel;
  final Function(double)? onChanged;
  final bool valueAsInt;

  const GoalSettingSlider({
    Key? key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.stepSize,
    required this.valueLabel,
    this.onChanged,
    this.valueAsInt = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: SubHeader(text: title, context: context),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 48),
                  BoldSubHeader(text: (valueAsInt ? value.toInt() : value).toString(), context: context),
                  BoldContent(
                    text: valueLabel,
                    context: context,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
                  )
                ],
              )
            ],
          ),
        ),
        Slider(
          min: min,
          max: max,
          divisions: (max / stepSize - min / stepSize).toInt(),
          value: value,
          onChanged: onChanged,
          inactiveColor: CI.blue.withOpacity(0.15),
          activeColor: CI.blue,
        ),
      ],
    );
  }
}
