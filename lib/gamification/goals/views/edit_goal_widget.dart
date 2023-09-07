import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/text.dart';

class EditGoalWidget extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final double stepSize;
  final String valueLabel;
  final Function(double)? onChanged;
  final bool valueAsInt;

  const EditGoalWidget({
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.025),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          EditButton(
            icon: Icons.remove,
            onPressed: (onChanged == null || value <= min) ? null : () => onChanged!(value - stepSize),
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
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(onChanged == null ? 0.5 : 1),
                    ),
                    const SizedBox(width: 4),
                    BoldContent(
                      text: valueLabel,
                      context: context,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(onChanged == null ? 0.5 : 1),
                    ),
                  ],
                ),
                BoldSmall(
                  text: title,
                  context: context,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(onChanged == null ? 0.1 : 0.2),
                )
              ],
            ),
          ),
          EditButton(
            icon: Icons.add,
            onPressed: (onChanged == null || value >= max) ? null : () => onChanged!(value + stepSize),
          ),
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
  bool get disable => widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        splashColor: disable ? Colors.transparent : Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
        onTapDown: (_) => HapticFeedback.lightImpact(),
        onTap: disable
            ? null
            : () {
                if (widget.onPressed != null) widget.onPressed!();
              },
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(disable ? 0.05 : 0.1),
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: 32,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(disable ? 0.25 : 1),
            ),
          ),
        ),
      ),
    );
  }
}
