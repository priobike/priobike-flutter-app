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
  static const Color bronzeColor = Color.fromRGBO(169, 113, 66, 1);
  static const Color silverColor = Color.fromRGBO(165, 169, 180, 1);
  static const Color goldColor = Color.fromRGBO(212, 175, 55, 1);

  /// These are the levels that are possible to achieve by the user vie their xp.
  static List<Level> levels = [
    Level(value: 500, title: '', color: bronzeColor.withOpacity(0.5)),
    const Level(value: 1000, title: '', color: bronzeColor),
    Level(value: 1500, title: '', color: silverColor.withOpacity(0.5)),
    const Level(value: 2000, title: '', color: silverColor),
    Level(value: 2500, title: '', color: goldColor.withOpacity(0.5)),
    const Level(value: 3000, title: '', color: goldColor),
    const Level(value: 3500, title: '', color: Medals.priobike),
  ];

  /// The service which manages and provides the user profile.
  late GameProfileService _profileService;

  /// The service which provides the users game settings to modify the card according to the enabled features.
  late GameSettingsService _settingsService;

  /// Controller to animate the trophy icon when a new trophy is gained.
  late final AnimationController _trophiesController;

  /// Controller to animate the medal icon when a new medal is gained.
  late final AnimationController _medalsController;

  /// Bounce animation for the trophy or medal icon.
  Animation<double> getAnimation(var controller) =>
      Tween<double>(begin: 1, end: 2).animate(CurvedAnimation(parent: controller, curve: Curves.bounceIn));

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
    _trophiesController = AnimationController(duration: ShortTransitionDuration(), vsync: this);
    _medalsController = AnimationController(duration: ShortTransitionDuration(), vsync: this);
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

  /// Create level rings, such that the ring indicators fit to the current users xp and the levels.
  List<Level> getRingLevels() {
    var next = nextLevel;
    if (next == null) {
      var endLevel = levels.last;
      return levels.map((e) => endLevel).toList();
    } else {
      List<Level> result = [];
      var prevValue = currentLevel?.value ?? 0;
      var valueDiff = next.value - prevValue;
      for (int i = 0; i < 7; i++) {
        var subValue = prevValue + (i + 1) * (valueDiff ~/ 7);
        var level = Level(value: subValue, title: '', color: next.color);
        result.add(level);
      }
      return result;
    }
  }

  /// Get the current level of the user according to their xp. Returns null if the user hasn't reached a level yet.
  Level? get currentLevel {
    Level? prevLvl;
    for (var level in levels) {
      if (_profileService.profile!.xp < level.value) break;
      prevLvl = level;
    }
    return prevLvl;
  }

  /// Return the next level the user needs to achieve. Returns null, if the user has reached the max level.
  Level? get nextLevel {
    if (currentLevel == null) return levels[0];
    int index = levels.indexOf(currentLevel!);
    if (index == levels.length - 1) return null;
    return levels[index + 1];
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

  /// Get card header which displays the users game state in form of the received rewards.
  Widget getRewardsHeader(var profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        GestureDetector(
          onTap: animateRing,
          child: AnimatedLevelRing(
            levels: getRingLevels(),
            value: profile.xp.toDouble(),
            color: (currentLevel == null)
                ? Theme.of(context).colorScheme.onBackground.withOpacity(0.25)
                : currentLevel!.color,
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
                      context: context,
                    ),
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

  /// Get card header without a game state.
  Widget getNoRewardsHeader(var profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.person,
          size: 32,
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
        ),
        const SmallHSpace(),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: BoldSubHeader(
            text: profile.username,
            context: context,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
          ),
        ),
        const HSpace(),
      ],
    );
  }

  /// Widget which displays the total statisics for the user.
  Widget getStatisticFooter(var profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  /// Get seperator between header and footer of the card.
  Widget getSeperator() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8, left: 8, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                  color: CI.blue.withOpacity(0.025),
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  boxShadow: [
                    BoxShadow(
                      color: CI.blue.withOpacity(0.025),
                      blurRadius: 5,
                    )
                  ]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var profile = _profileService.profile!;
    var rewardsEnabled = _settingsService.isFeatureEnabled(GameSettingsService.gameFeatureChallengesKey);
    var statsEnabled = _settingsService.isFeatureEnabled(GameSettingsService.gameFeatureStatisticsKey);
    return GameHubCard(
      content: Column(
        children: [
          const SmallVSpace(),
          rewardsEnabled ? getRewardsHeader(profile) : getNoRewardsHeader(profile),
          if (statsEnabled & !rewardsEnabled) getSeperator(),
          if (statsEnabled) getStatisticFooter(profile),
          const SmallVSpace(),
        ],
      ),
    );
  }
}
