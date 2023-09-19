import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';

/// The different kind of stats that can describe a ride.
enum StatType {
  distance,
  duration,
  elevationGain,
  elevationLoss,
  speed,
}

/// Get icon describing a given ride info type.
IconData getIconForInfoType(StatType type) {
  if (type == StatType.distance) return Icons.directions_bike;
  if (type == StatType.speed) return Icons.speed;
  if (type == StatType.duration) return Icons.timer;
  if (type == StatType.elevationGain) return CustomGameIcons.elevation_gain;
  if (type == StatType.elevationLoss) return CustomGameIcons.elevation_loss;
  return Icons.question_mark;
}
