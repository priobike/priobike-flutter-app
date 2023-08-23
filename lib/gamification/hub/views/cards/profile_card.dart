import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/game/colors.dart';
import 'package:priobike/game/models.dart';
import 'package:priobike/game/view.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/hub/services/profile_service.dart';
import 'package:priobike/gamification/hub/views/cards/hub_card.dart';
import 'package:priobike/gamification/settings/services/settings_service.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/gamification/statistics/views/utils.dart';
import 'package:priobike/main.dart';

/// This view displays the basic info about the users game profile. This contains their achieved game awards and
/// their overall statistics of all registered rides.
class GameProfileCard extends StatefulWidget {
  const GameProfileCard({Key? key}) : super(key: key);

  @override
  State<GameProfileCard> createState() => _GameProfileCardState();
}

class _GameProfileCardState extends State<GameProfileCard> with TickerProviderStateMixin {
  /// The service which manages and provides the user profile.
  late GameProfileService _profileService;

  late GameSettingsService _settingsService;

  late final AnimationController _trophiesController = AnimationController(
    duration: ShortTransitionDuration(),
    vsync: this,
  );

  late final AnimationController _medalsController = AnimationController(
    duration: ShortTransitionDuration(),
    vsync: this,
  );

  Animation<double> getAnimation(var controller) =>
      Tween<double>(begin: 1, end: 2).animate(CurvedAnimation(parent: controller, curve: Curves.bounceIn));

  /// These are the levels that are possible to achieve by the user vie their xp.
  static List<Level> get _levels => const [
        Level(value: 100, title: 'Laie', color: Medals.bronze),
        Level(value: 250, title: 'Beginner', color: Medals.bronze),
        Level(value: 500, title: "Ganz oke bro", color: Medals.silver),
        Level(value: 1000, title: "Kranke Sau Du!", color: Medals.silver),
        Level(value: 2500, title: "So gut ALDA!", color: Medals.gold),
        Level(value: 5000, title: "Fahrradsau", color: Medals.gold),
        Level(value: 10000, title: "Gottheit", color: Medals.priobike),
      ];

  /// This bool determines wether the displayed level ring should be animated currently.
  bool animateLevelRing = false;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() async {
    if (mounted) setState(() {});
    if (_profileService.medalsChanged) {
      await _medalsController.reverse(from: 1);
      _profileService.medalsChanged = false;
      if (mounted) setState(() {});
    } else if (_profileService.trophiesChanged) {
      await _trophiesController.reverse(from: 1);
      _profileService.trophiesChanged = false;
      if (mounted) setState(() {});
    }
  }

  /// This function starts and ends the level ring animation.
  void animateRing() {
    setState(() => animateLevelRing = true);
    Future.delayed(LongTransitionDuration()).then((_) => setState(() => animateLevelRing = false));
  }

  @override
  void initState() {
    _profileService = getIt<GameProfileService>();
    _profileService.addListener(update);
    _settingsService = getIt<GameSettingsService>();
    _settingsService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _medalsController.dispose();
    _trophiesController.dispose();
    _profileService.removeListener(update);
    _settingsService.removeListener(update);
    super.dispose();
  }

  /// Get the current level of the user according to their xp. Returns null if the user hasn't reached a level yet.
  Level? get currentLevel {
    Level? prevLvl;
    for (var level in _levels) {
      if (_profileService.profile!.xp < level.value) break;
      prevLvl = level;
    }
    return prevLvl;
  }

  /// Return the next level the user needs to achieve. Returns null, if the user has reached the max level.
  Level? get nextLevel {
    if (currentLevel == null) return _levels[0];
    int index = _levels.indexOf(currentLevel!);
    if (index == _levels.length - 1) return null;
    return _levels[index + 1];
  }

  /// Returns widget for displaying a trophy count for a trophy with a given icon.
  Widget getTrophyWidget(int number, IconData icon, Animation<double> animation, bool animate) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: animation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CI.blue.withOpacity(animate ? 0.25 : 0),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 36,
              color: animate ? CI.blue : Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
        ),
        BoldContent(
          text: 'x $number',
          context: context,
        ),
      ],
    );
  }

  /// Returns an info widget for a given value with a given label and icon.
  Widget getInfoWidget(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 24,
          color: CI.blue.withOpacity(0.25),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            BoldSmall(
              text: value,
              context: context,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
            BoldSmall(
              text: label,
              context: context,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
            ),
          ],
        ),
      ],
    );
  }

  Widget getGameHeader(var profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        GestureDetector(
          onTap: animateRing,
          child: AnimatedLevelRing(
            levels: _levels,
            value: profile.xp.toDouble(),
            color: currentLevel?.color ?? CI.blue.withOpacity(0.25),
            icon: Icons.directions_bike,
            ringSize: 96,
            buildWithAnimation: animateLevelRing,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BoldSubHeader(text: _profileService.profile!.username, context: context),
                    Small(
                        text: (nextLevel == null) ? '${profile.xp} XP' : '${profile.xp} / ${nextLevel!.value} XP',
                        context: context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  getTrophyWidget(
                    profile.medals,
                    Icons.military_tech,
                    getAnimation(_medalsController),
                    _profileService.medalsChanged,
                  ),
                  getTrophyWidget(
                    profile.trophies,
                    Icons.emoji_events,
                    getAnimation(_trophiesController),
                    _profileService.trophiesChanged,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget getNoGameHeader(var profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Header(text: profile.username, context: context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var profile = _profileService.profile!;
    return GameHubCard(
      content: Column(
        children: [
          const SmallVSpace(),
          (_settingsService.isFeatureEnabled(GameSettingsService.gameFeatureChallengesKey))
              ? getGameHeader(profile)
              : getNoGameHeader(profile),
          const SmallVSpace(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              getInfoWidget(
                Icons.directions_bike,
                StatUtils.getRoundedStrByRideType(profile.totalDistanceKilometres, RideInfo.distance),
                'km',
              ),
              getInfoWidget(
                Icons.timer,
                StatUtils.getRoundedStrByRideType(profile.totalDurationMinutes, RideInfo.duration),
                'min',
              ),
              getInfoWidget(
                Icons.speed,
                'ø ${StatUtils.getRoundedStrByRideType(profile.averageSpeedKmh, RideInfo.averageSpeed)}',
                'km/h',
              ),
              getInfoWidget(
                Icons.arrow_upward,
                StatUtils.getRoundedStrByRideType(profile.totalElevationGainMetres, RideInfo.elevationGain),
                'm',
              ),
              getInfoWidget(
                Icons.arrow_downward,
                StatUtils.getRoundedStrByRideType(profile.totalElevationLossMetres, RideInfo.elevationLoss),
                'm',
              ),
            ],
          ),
          const SmallVSpace(),
        ],
      ),
    );
  }
}
