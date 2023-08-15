import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/game/colors.dart';
import 'package:priobike/game/models.dart';
import 'package:priobike/game/view.dart';
import 'package:priobike/gamification/hub/services/game_service.dart';
import 'package:priobike/main.dart';

class TotalStatisticsView extends StatelessWidget {
  TotalStatisticsView({Key? key}) : super(key: key);

  /// padding for the rows used in the statistics view
  final double paddingStats = 16.0;

  final GameService _gameService = getIt<GameService>();

  Widget renderDistanceStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        alignment: Alignment.centerRight,
        child: LevelView(
          levels: const [
            // Bronze levels
            Level(value: 0, title: "Meilen-Mampfer", color: Medals.bronze),
            Level(value: 50, title: "Zweirad-Wanderer", color: Medals.bronze),
            // Silver levels
            Level(value: 100, title: "Radfahr-Begleiter", color: Medals.silver),
            Level(value: 150, title: "Fahrrad-Buddha", color: Medals.silver),
            // Gold levels
            Level(value: 250, title: "Velociped-Virtuose", color: Medals.gold),
            Level(value: 500, title: "Sattel-Kenner", color: Medals.gold),
            // PrioBike (Blue) levels
            Level(value: 1000, title: "Radfahr-Champion", color: Medals.priobike),
          ],
          value: (_gameService.totalDistanceMetres) / 1000,
          icon: Icons.directions_bike_rounded,
          unit: "km",
        ),
      ),
    );
  }

  Widget renderDurationStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        alignment: Alignment.centerRight,
        child: LevelView(
          levels: const [
            // Bronze levels
            Level(value: 0, title: "Radel-Rookie", color: Medals.bronze),
            Level(value: 10, title: "Mittelstrecken-Fahrer", color: Medals.bronze),
            // Silver levels
            Level(value: 30, title: "Dauerläufer", color: Medals.silver),
            Level(value: 180, title: "Bike-Boss", color: Medals.silver),
            // Gold levels
            Level(value: 600, title: "Pedal-Powerhouse", color: Medals.gold),
            Level(value: 1200, title: "Tour de Force", color: Medals.gold),
            // PrioBike (Blue) levels
            Level(value: 3000, title: "Radrennen-Routinier", color: Medals.priobike),
          ],
          value: (_gameService.totalDurationSeconds) / 60,
          icon: Icons.timer_outlined,
          unit: "min",
        ),
      ),
    );
  }

  Widget renderSpeedStats(BuildContext context) {
    return Row(
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(top: paddingStats, bottom: paddingStats),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BoldContent(
                text: "⌀ ${(_gameService.averageSpeedKmh).round()} km/h",
                context: context,
              ),
              const SizedBox(height: 4),
              Small(text: "Geschwindigkeit", context: context),
            ],
          ),
        ),
        const HSpace(),
        Expanded(child: Container()),
        Container(
          alignment: Alignment.centerRight,
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              Icons.speed_rounded,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(text: _gameService.username, context: context),
        renderDistanceStats(),
        renderDurationStats(),
        renderSpeedStats(context),
      ],
    );
  }
}
