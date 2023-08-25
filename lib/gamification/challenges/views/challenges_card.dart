import 'dart:async';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/views/progress_bar.dart';
import 'package:priobike/gamification/challenges/views/goal_setting.dart';
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

  @override
  Widget build(BuildContext context) {
    return GameHubCard(
      onTap: () async {
        // Open view to set goals., if the user hasn't set their goals yet.
        if (!_settingsService.challengeGoalsSet) widget.openView(const ChallengeGoalSetting());
      },
      content: Column(
        children: _settingsService.challengeGoalsSet
            // If the user has set their challenge goals, show progress bars for daily and weekly challenges and a
            // small button to update the goals.
            ? [
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
              ]
            // If the user hasn't set their goals, show info widget.
            : [
                getNoGoalsWidget(),
              ],
      ),
    );
  }

  /// Info widget which encourages the user to set their goals.
  Widget getNoGoalsWidget() {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoldSubHeader(text: 'PrioBike Challenges', context: context),
            Small(
              text: 'Bestreite tägliche und wöchentliche Challenges, steige Level auf uns sammel Abzeichen und Orden.',
              context: context,
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                BoldSmall(text: 'Challenges Starten', context: context),
                const SizedBox(width: 4),
                const Icon(Icons.redo, size: 16),
              ],
            ),
          ],
        ));
  }
}
