import 'package:flutter/material.dart';

/// This widget displays a badge with a given size, a given color and with a given icon to display on top of it.
class RewardBadge extends StatelessWidget {
  final Color color;

  final double size;

  final int iconIndex;

  final bool achieved;

  const RewardBadge(
      {super.key, required this.color, required this.size, required this.iconIndex, required this.achieved});

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
                getIcon(iconIndex),
                size: size / 2,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

IconData getIcon(int value) {
  if (value == 0) return Icons.star;
  if (value == 1) return Icons.nightlight_round;
  if (value == 2) return Icons.public;
  if (value == 3) return Icons.water_drop;
  if (value == 4) return Icons.location_city;
  if (value == 5) return Icons.whatshot;
  if (value == 6) return Icons.cyclone;
  if (value == 7) return Icons.bolt;
  if (value == 8) return Icons.wb_sunny;
  if (value == 9) return Icons.landscape;
  if (value == 10) return Icons.filter_vintage;
  if (value == 11) return Icons.wb_cloudy;
  if (value == 12) return Icons.looks;
  if (value == 13) return Icons.park;
  if (value == 14) return Icons.traffic;
  if (value == 15) return Icons.sailing;
  if (value == 16) return Icons.forest;
  if (value == 17) return Icons.signpost;
  if (value == 18) return Icons.air;
  if (value == 19) return Icons.grass;
  return Icons.question_mark;
}
