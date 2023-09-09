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
  Level(value: 0, title: 'Novize', color: Colors.transparent),
  Level(value: 50, title: 'Rad-Rookie', color: Medals.mattBronze),
  Level(value: 100, title: 'Freizeitradler', color: Medals.bronze),
  Level(value: 250, title: 'Sattel-Routinier', color: Medals.mattSilver),
  Level(value: 500, title: 'Stadtsprinter', color: Medals.silver),
  Level(value: 1000, title: 'Pedal-Profi', color: Medals.mattGold),
  Level(value: 2500, title: 'Fahrrad-Flüsterer', color: Medals.gold),
  Level(value: 5000, title: 'Radsport-Legende', color: Medals.priobike),
];
