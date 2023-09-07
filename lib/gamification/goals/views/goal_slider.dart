import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';

class GoalSettingWidget extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final double stepSize;
  final String valueLabel;
  final Function(double)? onChanged;
  final bool valueAsInt;

  const GoalSettingWidget({
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const SmallHSpace(),
          EditButton(
            icon: Icons.remove,
            onPressed: onChanged == null ? null : () => onChanged!(value - stepSize),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BoldSubHeader(
                      text: (valueAsInt ? value.toInt() : value).toString(),
                      context: context,
                    ),
                    const SizedBox(width: 4),
                    BoldContent(
                      text: valueLabel,
                      context: context,
                    ),
                  ],
                ),
                BoldSmall(
                  text: title,
                  context: context,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
                )
              ],
            ),
          ),
          EditButton(
            icon: Icons.add,
            onPressed: onChanged == null ? null : () => onChanged!(value + stepSize),
          ),
          const SmallHSpace(),
        ],
      ),
    );
  }
}

class EditButton extends StatefulWidget {
  final IconData icon;

  final Function()? onPressed;

  const EditButton({Key? key, required this.icon, required this.onPressed}) : super(key: key);

  @override
  State<EditButton> createState() => _EditButtonState();
}

class _EditButtonState extends State<EditButton> with SingleTickerProviderStateMixin {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) {
        if (widget.onPressed == null) return;
        setState(() => isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        if (widget.onPressed == null) return;
        setState(() => isPressed = false);
        widget.onPressed!();
      },
      onTapCancel: () => setState(() => isPressed = false),
      child: SizedBox.fromSize(
        size: const Size.square(48),
        child: Center(
          child: Icon(
            widget.icon,
            size: 48,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(isPressed ? 0.25 : 1),
          ),
        ),
      ),
    );
  }
}
