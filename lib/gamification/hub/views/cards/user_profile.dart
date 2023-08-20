import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/game/colors.dart';
import 'package:priobike/game/models.dart';
import 'package:priobike/game/view.dart';
import 'package:priobike/gamification/hub/services/profile_service.dart';
import 'package:priobike/gamification/hub/views/cards/hub_card.dart';
import 'package:priobike/main.dart';

/// A gamification hub card, which displays basic info about the user profile.
class UserProfileCard extends StatelessWidget {
  UserProfileCard({Key? key}) : super(key: key);

  final GameProfileService _gameService = getIt<GameProfileService>();

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
            Level(value: 10000, title: "Radfahr-Champion", color: Medals.priobike),
          ],
          value: (_gameService.userProfile!.totalDistanceKilometres),
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
            Level(value: 30000, title: "Radrennen-Routinier", color: Medals.priobike),
          ],
          value: (_gameService.userProfile!.totalDurationMinutes),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BoldContent(
                text: "⌀ ${(_gameService.userProfile!.averageSpeedKmh).round()} km/h",
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
    return GameHubCard(
      content: Column(
        children: [
          const SmallVSpace(),
          Header(text: _gameService.userProfile!.username, context: context),
          renderDistanceStats(),
          renderDurationStats(),
          renderSpeedStats(context),
        ],
      ),
    );
  }
}
