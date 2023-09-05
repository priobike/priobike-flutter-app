import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/challenges/models/challenge_goals.dart';
import 'package:priobike/gamification/common/views/custom_page.dart';
import 'package:priobike/gamification/settings/services/settings_service.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/views/shortcuts/selection.dart';
import 'package:priobike/main.dart';
import 'package:priobike/home/services/shortcuts.dart';

class ChallengeGoalSetting extends StatefulWidget {
  const ChallengeGoalSetting({Key? key}) : super(key: key);

  @override
  State<ChallengeGoalSetting> createState() => _ChallengeGoalSettingState();
}

class _ChallengeGoalSettingState extends State<ChallengeGoalSetting> with SingleTickerProviderStateMixin {
  static const double distanceGoalDefault = 2.5;
  static const double durationGoalDefault = 30;
  static const double perWeekGoalDefault = 3;

  /// Controller which controls the animation when opening this view.
  late AnimationController _animationController;

  /// The game settings service to get the current user goals and to update the user goals if needed.
  late GameSettingsService _settingsService;

  /// The associated shortcuts service
  late Shortcuts _shortcutsService;

  /// The scroll controller.
  ScrollController scrollController = ScrollController();

  /// The ride distance per day user goal.
  double distanceGoal = distanceGoalDefault;

  /// The ride duration per day user goal.
  double durationGoal = durationGoalDefault;

  /// The rides per week route goal.
  double routeGoal = perWeekGoalDefault;

  /// The rides per week location goal.
  double locationGoal = perWeekGoalDefault;

  /// The id of the currently selected route.
  String? selectedRoute;

  /// The id of the currently selected location.
  String? selectedLocation;

  /// Whether to show the route selection to the user. Fals at the beginning to avoid overwhelming the user.
  bool showRouteSelection = false;

  /// Whether to show the location selection to the user. Fals at the beginning to avoid overwhelming the user.
  bool showLocationSelection = false;

  /// List of saved routes of the user from the shortcut service.
  List<ShortcutRoute> get routes => _shortcutsService.shortcuts?.whereType<ShortcutRoute>().toList() ?? [];

  /// List of saved locations of the user from the shortcut service.
  List<ShortcutLocation> get locations => _shortcutsService.shortcuts?.whereType<ShortcutLocation>().toList() ?? [];

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  @override
  void initState() {
    _settingsService = getIt<GameSettingsService>();
    _settingsService.addListener(update);
    _shortcutsService = getIt<Shortcuts>();
    _shortcutsService.addListener(update);
    _animationController = AnimationController(vsync: this, duration: LongDuration());
    _animationController.forward();

    // Update default values to previous goals, if previous goals exist.
    var goals = _settingsService.challengeGoals;
    var routeGoals = goals.routeGoal;
    showRouteSelection = routeGoals != null;
    distanceGoal = goals.dailyDistanceGoalMetres / 1000;
    durationGoal = goals.dailyDurationGoalMinutes;
    selectedRoute = routeGoals?.routeID;

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
    return CustomPage(
      animationController: _animationController,
      title: 'Deine Ziele',
      content: Column(
        children: [
          const SmallVSpace(),
          getGoalSlider(
            title: 'Distanz-Ziel pro Tag',
            value: distanceGoal,
            min: 0.5,
            max: 10,
            stepSize: 0.5,
            valueLabel: 'km',
            onChanged: (value) => setState(() => distanceGoal = value),
            valueAsInt: false,
          ),
          const SmallVSpace(),
          getGoalSlider(
            title: 'Zeit-Ziel pro Tag',
            value: durationGoal,
            min: 10,
            max: 90,
            stepSize: 10,
            valueLabel: 'min',
            onChanged: (value) => setState(() => durationGoal = value),
          ),
          const SmallVSpace(),
          getSelectionWithSlider(
            shortcutLabel: 'Routen',
            showSelection: showRouteSelection,
            infoText: 'Möchtest du dir vornehmen, eine deiner gespeicherten Strecken regelmäßig zu fahren?',
            sliderValue: routeGoal,
            selectedShortcut: selectedRoute,
            updateSlider: (value) => routeGoal = value,
            shortcuts: routes,
            enableSelection: () => showRouteSelection = true,
            updateSelectedShortcut: (id) {
              if (id == selectedRoute) {
                selectedRoute = null;
              } else {
                selectedRoute = id;
              }
            },
          ),
          const SmallVSpace(),
          getSelectionWithSlider(
            shortcutLabel: 'Orte',
            showSelection: showLocationSelection,
            infoText: 'Möchtest du dir vornehmen regelmäßig Fahrten zu einem deiner gespeicherten Orte zu unternehmen?',
            sliderValue: locationGoal,
            selectedShortcut: selectedLocation,
            updateSlider: (value) => locationGoal = value,
            shortcuts: locations,
            enableSelection: () => showLocationSelection = true,
            updateSelectedShortcut: (id) {
              if (id == selectedLocation) {
                selectedLocation = null;
              } else {
                selectedLocation = id;
              }
            },
          ),
          const VSpace(),
          BigButton(
            label: 'Ziele Speichern',
            onPressed: () {
              var route = _shortcutsService.shortcuts?.where((s) => s.id == selectedRoute).firstOrNull;
              var routeGoals = route == null ? null : RouteGoals(route.id, route.name, routeGoal.toInt());
              var goals = UserGoals(distanceGoal * 1000, durationGoal, routeGoals);
              getIt<GameSettingsService>().setChallengeGoals(goals);
              Navigator.pop(context);
            },
          ),
          const VSpace(),
        ],
      ),
    );
  }

  /// This widget includes a slider connected to a given value, which can be used to change the value.
  Widget getGoalSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required double stepSize,
    required String valueLabel,
    required Function(double)? onChanged,
    bool valueAsInt = true,
    Widget? bottomView,
  }) {
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
                    child: SubHeader(text: title, context: context),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(width: 48),
                      BoldSubHeader(text: (valueAsInt ? value.toInt() : value).toString(), context: context),
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
            if (bottomView != null) bottomView,
          ],
        ),
      ),
    );
  }

  /// This widget displays a selection slider connected to a list of route or location shortcuts.
  Widget getSelectionWithSlider({
    required String infoText,
    required double sliderValue,
    required String? selectedShortcut,
    required Function(double) updateSlider,
    required List<Shortcut> shortcuts,
    required Function(String) updateSelectedShortcut,
    required Function() enableSelection,
    required bool showSelection,
    required String shortcutLabel,
  }) {
    const double shortcutRightPad = 16;
    final shortcutWidth = (MediaQuery.of(context).size.width / 2) - shortcutRightPad;
    final shortcutHeight = max(shortcutWidth - (shortcutRightPad * 3), 128.0);
    return Column(
      children: [
        const SmallVSpace(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: BoldSmall(
            text: infoText,
            context: context,
            textAlign: TextAlign.center,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.75),
          ),
        ),
        const SmallVSpace(),
        if (showSelection)
          getGoalSlider(
            title: 'Fahrten pro Woche',
            value: sliderValue,
            min: 1,
            max: 7,
            stepSize: 1,
            valueLabel: 'mal',
            onChanged: selectedShortcut == null ? null : (value) => setState(() => updateSlider(value)),
            bottomView: Padding(
              padding: const EdgeInsets.only(top: 8, left: 20),
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                    children: shortcuts
                        .map((shortcut) => ShortcutView(
                              onPressed: () => setState(() => updateSelectedShortcut(shortcut.id)),
                              shortcut: shortcut,
                              width: shortcutWidth,
                              height: shortcutHeight,
                              rightPad: shortcutRightPad,
                              selected: shortcut.id == selectedShortcut,
                              showSplash: false,
                            ))
                        .toList()),
              ),
            ),
          ),
        if (!showSelection)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Tile(
              onPressed: (shortcuts.isEmpty) ? null : () => setState(enableSelection),
              padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
              fill: Theme.of(context).colorScheme.background,
              content: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: (shortcuts.isNotEmpty)
                          ? [
                              Expanded(
                                child: SubHeader(text: 'Ziele setzen', context: context),
                              ),
                              const Icon(Icons.redo, size: 24),
                            ]
                          : [
                              Expanded(
                                child: BoldContent(
                                    text:
                                        'Du hast noch keine eigenen $shortcutLabel gespeichert. Du kannst dieses Ziel aber auch nachträglich noch setzen.',
                                    context: context,
                                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25)),
                              ),
                              const SmallHSpace(),
                              Icon(
                                Icons.not_interested,
                                size: 48,
                                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
                              ),
                            ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
