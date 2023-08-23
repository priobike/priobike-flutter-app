import 'dart:math';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/hub/challenges/utils/challenge_goals.dart';
import 'package:priobike/gamification/hub/views/custom_hub_page.dart';
import 'package:priobike/gamification/settings/services/settings_service.dart';
import 'package:priobike/home/views/shortcuts/selection.dart';
import 'package:priobike/main.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/shortcuts.dart';

class ChallengeGoalsView extends StatefulWidget {
  const ChallengeGoalsView({Key? key}) : super(key: key);

  @override
  State<ChallengeGoalsView> createState() => _ChallengeGoalsViewState();
}

class _ChallengeGoalsViewState extends State<ChallengeGoalsView> with SingleTickerProviderStateMixin {
  /// Controller which controls the animation when opening this view.
  late AnimationController _animationController;

  late GameSettingsService _settingsService;

  /// The associated shortcuts service
  late Shortcuts _shortcutsService;

  /// The scroll controller.
  ScrollController scrollController = ScrollController();

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  double distanceGoal = 2.5;

  double durationGoal = 30;

  double routeGoal = 4;

  String? selectedTrack;

  @override
  void initState() {
    _settingsService = getIt<GameSettingsService>();
    _settingsService.addListener(update);
    _shortcutsService = getIt<Shortcuts>();
    _shortcutsService.addListener(update);
    _animationController = AnimationController(vsync: this, duration: LongTransitionDuration());
    _animationController.forward();
    var prevGoals = _settingsService.challengeGoals;
    if (prevGoals != null) {
      var trackGoals = prevGoals.trackGoal;
      distanceGoal = prevGoals.dailyDistanceGoalMetres / 1000;
      durationGoal = prevGoals.dailyDurationGoalMinutes;
      selectedTrack = trackGoals?.trackDescription;
    }
    super.initState();
  }

  @override
  void dispose() {
    _settingsService.removeListener(update);
    _shortcutsService.removeListener(update);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameHubPage(
      animationController: _animationController,
      title: 'PrioBike Challenge',
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: BoldSmall(
                      text:
                          'Bevor Du mit den Challenges startest, setze Dir eigene Ziele. Die Challenges und ihre Schwierigkeit orientieren sich dann an diesen Zielen.',
                      context: context),
                ),
              ],
            ),
          ),
          const VSpace(),
          getGoalSlider(
            'Welche Distanz würdest Du im Durchschnitt gerne täglich mit dem Fahrrad zurücklegen?',
            distanceGoal,
            0.5,
            10,
            0.5,
            'km',
            (value) => setState(() => distanceGoal = value),
          ),
          const SmallVSpace(),
          getGoalSlider(
            'Wie lange würdest Du im Durchschnitt am Tag gerne Fahrradfahren?',
            durationGoal,
            10,
            90,
            10,
            'min',
            (value) => setState(() => durationGoal = value),
          ),
          const SmallVSpace(),
          getRouteSelection(),
          const VSpace(),
          BigButton(
            label: 'Challenges Starten',
            onPressed: () {
              var routeGoals =
                  selectedTrack == null ? null : RouteGoals(selectedTrack!, selectedTrack!, routeGoal.toInt());
              var goals = ChallengeGoals(distanceGoal * 1000, durationGoal, routeGoals);
              getIt<GameSettingsService>().setChallengeGoals(goals);
              Navigator.pop(context);
            },
          ),
          const VSpace(),
        ],
      ),
    );
  }

  Widget getGoalSlider(
    String title,
    double value,
    double min,
    double max,
    double stepSize,
    String valueLabel,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Tile(
        padding: const EdgeInsets.fromLTRB(0, 16, 8, 8),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
        fill: Theme.of(context).colorScheme.background,
        content: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Content(text: title, context: context),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(width: 48),
                      BoldSubHeader(text: value.toString(), context: context),
                      BoldContent(
                        text: valueLabel,
                        context: context,
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
                      )
                    ],
                  )
                ],
              ),
            ),
            Slider(
              min: min,
              max: max,
              divisions: (max / stepSize - min / stepSize).toInt(),
              value: value,
              onChanged: onChanged,
              inactiveColor: CI.blue.withOpacity(0.15),
              activeColor: CI.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget getRouteSelection() {
    const double shortcutRightPad = 16;
    final shortcutWidth = (MediaQuery.of(context).size.width / 2) - shortcutRightPad - 12;
    final shortcutHeight = max(shortcutWidth - (shortcutRightPad * 3), 128.0);
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Tile(
        padding: const EdgeInsets.fromLTRB(0, 16, 8, 0),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
        fill: Theme.of(context).colorScheme.background,
        content: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Content(
                        text:
                            'Möchtest Du Dir vornehmen eine deiner Routen öfter mit dem Fahrrad zu fahren, zum Beispiel deinen Arbeitsweg?',
                        context: context),
                  ),
                ],
              ),
            ),
            ...(selectedTrack != null)
                ? [
                    const SmallVSpace(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          BoldContent(text: 'Route:', context: context),
                          const SmallHSpace(),
                          Content(text: selectedTrack!, context: context)
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          BoldContent(text: 'Fahrten pro Woche:', context: context),
                          const SmallHSpace(),
                          Content(text: routeGoal.toInt().toString(), context: context)
                        ],
                      ),
                    ),
                    Slider(
                      min: 1,
                      max: 7,
                      divisions: 6,
                      value: routeGoal,
                      onChanged: (value) => setState(() => routeGoal = value),
                      inactiveColor: CI.blue.withOpacity(0.15),
                      activeColor: CI.blue,
                    ),
                  ]
                : [const SmallVSpace()],
            SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: _shortcutsService.shortcuts
                          ?.map((shortcut) => ShortcutView(
                                onPressed: () => setState(() {
                                  if (shortcut.name == selectedTrack) {
                                    selectedTrack = null;
                                  } else {
                                    selectedTrack = shortcut.name;
                                  }
                                }),
                                shortcut: shortcut,
                                width: shortcutWidth,
                                height: shortcutHeight,
                                rightPad: shortcutRightPad,
                              ))
                          .toList() ??
                      []),
            ),
          ],
        ),
      ),
    );
  }
}
