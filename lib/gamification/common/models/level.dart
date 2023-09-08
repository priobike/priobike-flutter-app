import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/colors.dart';

class Level {
  /// The value of the level.
  final int value;

  /// The title of the level.
  final String title;

  /// The color of the level.
  final Color color;

  const Level({
    required this.value,
    required this.title,
    required this.color,
  });
}

/// These are the levels that are possible to achieve by the user vie their xp.
List<Level> levels = const [
  Level(value: 0, title: 'Novice', color: Colors.transparent),
  Level(value: 25, title: 'Rookie', color: Medals.mattBronze),
  Level(value: 100, title: 'Casual Biker', color: Medals.bronze),
  Level(value: 1500, title: 'Regular', color: Medals.mattSilver),
  Level(value: 2000, title: 'Frequent Biker', color: Medals.silver),
  Level(value: 2500, title: 'Cycling Pro', color: Medals.mattGold),
  Level(value: 3000, title: 'King of Pedals', color: Medals.gold),
  Level(value: 3500, title: 'Biking Legend', color: Medals.priobike),
];
