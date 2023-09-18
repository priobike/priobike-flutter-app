import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/colors.dart';

/// A level, which can be reached by the user if they reach a certain xp value.
class Level {
  /// The value of the level.
  final int value;

  /// A short title for the level.
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
List<Level> levels = [
  Level(value: 0, title: 'Novize', color: LevelColors.grey),
  const Level(value: 10, title: 'Rad-Rookie', color: LevelColors.pink),
  const Level(value: 50, title: 'Freizeitradler', color: LevelColors.green),
  const Level(value: 200, title: 'Sattel-Routinier', color: LevelColors.bronze),
  const Level(value: 500, title: 'Stadtsprinter', color: LevelColors.silver),
  const Level(value: 1000, title: 'Pedal-Profi', color: LevelColors.gold),
  const Level(value: 2500, title: 'Fahrrad-Flüsterer', color: LevelColors.diamond),
  const Level(value: 5000, title: 'Radsport-Legende', color: LevelColors.priobike),
];
