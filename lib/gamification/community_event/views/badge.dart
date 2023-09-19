
import 'package:flutter/material.dart';

/// This widget displays a badge with a given size, a given color and with a given icon to display on top of it.
class RewardBadge extends StatelessWidget {
  final Color color;

  final double size;

  final IconData icon;

  final bool achieved;

  const RewardBadge({Key? key, required this.color, required this.size, required this.icon, required this.achieved})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: Size.square(size),
      child: Stack(
        children: [
          Icon(
            Icons.shield,
            color: achieved ? color : Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
            size: size,
          ),
          if (achieved)
            Center(
              child: Icon(
                icon,
                size: size / 2,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
