import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/hub/views/custom_hub_page.dart';
import 'package:priobike/gamification/settings/services/settings_service.dart';
import 'package:priobike/main.dart';

class ChallengeGoalsView extends StatefulWidget {
  const ChallengeGoalsView({Key? key}) : super(key: key);

  @override
  State<ChallengeGoalsView> createState() => _ChallengeGoalsViewState();
}

class _ChallengeGoalsViewState extends State<ChallengeGoalsView> with SingleTickerProviderStateMixin {
  /// Controller which controls the animation when opening this view.
  late AnimationController _animationController;

  late GameSettingsService _settingsService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  double slider1Value = 2.5;

  double slider2Value = 30;

  @override
  void initState() {
    _settingsService = getIt<GameSettingsService>();
    _settingsService.addListener(update);
    _animationController = AnimationController(vsync: this, duration: LongTransitionDuration());
    _animationController.forward();
    super.initState();
  }

  @override
  void dispose() {
    _settingsService.removeListener(update);
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
            slider1Value,
            0.5,
            10,
            0.5,
            'km',
            (value) => setState(() => slider1Value = value),
          ),
          const SmallVSpace(),
          getGoalSlider(
            'Wie lange würdest Du im Durchschnitt am Tag gerne Fahrradfahren?',
            slider2Value,
            10,
            90,
            10,
            'min',
            (value) => setState(() => slider2Value = value),
          ),
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
            )
          ],
        ),
      ),
    );
  }
}
