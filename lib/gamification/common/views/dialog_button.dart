import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/gamification/common/views/on_tap_animation.dart';

/// A custom button design for a button on a dialog.
class CustomDialogButton extends StatelessWidget {
  /// Color of the button.
  final Color color;

  /// Text label on the button.
  final String label;

  /// Callback function for when the button is pressed.
  final Function() onPressed;

  const CustomDialogButton({
    Key? key,
    required this.color,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OnTapAnimation(
        onPressed: onPressed,
        child: Tile(
          fill: color,
          padding: const EdgeInsets.symmetric(vertical: 8),
          borderRadius: BorderRadius.circular(24),
          content: Center(
            child: BoldSubHeader(
              text: label,
              context: context,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
