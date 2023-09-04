import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/views/progress_bar.dart';
import 'package:priobike/gamification/challenges/views/goal_setting.dart';
import 'package:priobike/gamification/common/colors.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/hub/views/hub_card.dart';
import 'package:priobike/gamification/settings/services/settings_service.dart';
import 'package:priobike/main.dart';

/// This card displays the current challenge state of the user or encourages them to set their challenge goals.
/// If no goals are set, the goal setting view can be opened by tapping the card. otherwise it can be opened by
/// tapping a button at the bottom.
class GameChallengesCard extends StatefulWidget {
  /// Open view function from parent widget is required, to animate the hub cards away when opening the stats view.
  final Future Function(Widget view) openView;

  const GameChallengesCard({Key? key, required this.openView}) : super(key: key);

  @override
  State<GameChallengesCard> createState() => _GameChallengesCardState();
}

class _GameChallengesCardState extends State<GameChallengesCard> {
  /// Game settings service required to check whether the user has set their challenge goals.
  late GameSettingsService _settingsService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  @override
  void initState() {
    _settingsService = getIt<GameSettingsService>();
    _settingsService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _settingsService.removeListener(update);
    super.dispose();
  }

  bool get _challengesActivated =>
      _settingsService.enabledFeatures.contains(GameSettingsService.gameFeatureChallengesKey);

  @override
  Widget build(BuildContext context) {
    // If the user has activated the challenges, show widget containing all the challenge information and functions.
    if (_challengesActivated) return getChallengeWidget();

    // If the user hasn't activated the challenges, show info widget.
    return getChallegnesDeactivedWidget();
  }

  Widget getChallengeWidget() {
    return GameHubCard(
      content: Column(
        children: [
          const ChallengeProgressBar(isWeekly: true),
          const ChallengeProgressBar(isWeekly: false),
          GestureDetector(
            onTap: () => widget.openView(const ChallengeGoalSetting()),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                BoldSmall(text: 'Ziele ändern', context: context),
                const SizedBox(width: 4),
                const Icon(Icons.redo, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Info widget which encourages the user to participate in the challenges.
  Widget getChallegnesDeactivedWidget() {
    return GameHubCard(
      onTap: () async {
        // Open view to set goals.
        widget.openView(const ChallengeGoalSetting());
      },
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BoldSubHeader(text: 'PrioBike Challenges', context: context),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Small(
                        text:
                            'Bestreite tägliche und wöchentliche Challenges, steige Level auf uns sammel Abzeichen und Orden.',
                        context: context,
                      ),
                    ),
                    SizedBox(
                      width: 96,
                      height: 80,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: Container(
                              width: 0,
                              height: 0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: CI.blue.withOpacity(0.1),
                                    blurRadius: 32,
                                    spreadRadius: 32,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.1),
                                    blurRadius: 32,
                                    spreadRadius: 32,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Transform.rotate(
                              angle: pi / 8,
                              child: const Icon(
                                CustomGameIcons.blankTrophy,
                                size: 64,
                                color: Medals.gold,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Transform.rotate(
                              angle: -pi / 8,
                              child: const Icon(
                                CustomGameIcons.medal,
                                size: 64,
                                color: CI.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
