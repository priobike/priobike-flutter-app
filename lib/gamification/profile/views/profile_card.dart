import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/profile/models/level.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/level_ring.dart';
import 'package:priobike/gamification/profile/services/profile_service.dart';
import 'package:priobike/gamification/hub/views/hub_card.dart';
import 'package:priobike/gamification/settings/services/settings_service.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/main.dart';

/// This view displays the basic info about the users game profile. This can contain their achieved game rewards and
/// their overall statistics of all registered rides. But what exactly is displayed depends on the users'
/// enabled gamification features.
class GameProfileCard extends StatefulWidget {
  const GameProfileCard({Key? key}) : super(key: key);

  @override
  State<GameProfileCard> createState() => _GameProfileCardState();
}

class _GameProfileCardState extends State<GameProfileCard> with TickerProviderStateMixin {
  /// The service which manages and provides the user profile.
  late GameProfileService _profileService;

  /// The service which provides the users game settings to modify the card according to the enabled features.
  late GameSettingsService _settingsService;

  /// Controller to animate the trophy icon when a new trophy is gained.
  late final AnimationController _trophiesController;

  /// Controller to animate the medal icon when a new medal is gained.
  late final AnimationController _medalsController;

  /// Animation Controller to controll the ring animation.
  late final AnimationController _ringController;

  /// Bounce animation for the trophy or medal icon.
  Animation<double> getAnimation(var controller) =>
      Tween<double>(begin: 1, end: 2).animate(CurvedAnimation(parent: controller, curve: Curves.bounceIn));

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() async {
    // First, rebuild the widget.
    if (mounted) setState(() {});
    // If the medals have changed, animate the medal icon.
    if (_profileService.medalsChanged) {
      await _medalsController.reverse(from: 1);
      _profileService.medalsChanged = false;
      if (mounted) setState(() {});
    }
    // If the trophies have changed, animate the trophy icon.
    else if (_profileService.trophiesChanged) {
      await _trophiesController.reverse(from: 1);
      _profileService.trophiesChanged = false;
      if (mounted) setState(() {});
    }
  }

  /// This function starts and ends the level ring animation.
  void animateRing() async {
    await _ringController.reverse();
    await Future.delayed(const Duration(milliseconds: 250));
    await _ringController.forward();
  }

  @override
  void initState() {
    _trophiesController = AnimationController(duration: ShortAnimationDuration(), vsync: this);
    _medalsController = AnimationController(duration: ShortAnimationDuration(), vsync: this);
    _ringController = AnimationController(vsync: this, duration: ShortAnimationDuration(), value: 1);
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

  /// Create level rings, such that the ring indicators match the current users xp and level.
  List<Level> getRingLevels() {
    var next = nextLevel;
    // If the max level has been reached, the whole ring is displayed in blue.
    if (next == null) {
      var endLevel = levels.last;
      return levels.map((e) => endLevel).toList();
    }
    // Else, the ring color depends on the next levels color and the current xp progress.
    else {
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
  Widget getTrophyWidget(int number, String imgPath, Animation<double> animation, bool animate) {
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
            child: SvgPicture.asset(
              imgPath,
              colorFilter: ColorFilter.mode(
                  animate ? CI.blue : Theme.of(context).colorScheme.onBackground.withOpacity(0.5), BlendMode.srcIn),
              width: 36,
              height: 36,
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
          child: LevelRing(
            minValue: currentLevel?.value.toDouble() ?? 0,
            maxValue: nextLevel?.value.toDouble() ?? profile.xp.toDouble(),
            curValue: profile.xp.toDouble(),
            iconColor: (currentLevel == null)
                ? Theme.of(context).colorScheme.onBackground.withOpacity(0.25)
                : currentLevel!.color,
            icon: Icons.directions_bike,
            ringSize: 96,
            animationController: _ringController,
            ringColor: nextLevel?.color ?? currentLevel!.color,
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
                    'assets/images/gamification/medal_clean.svg',
                    getAnimation(_medalsController),
                    _profileService.medalsChanged,
                  ),
                  getTrophyWidget(
                    profile.trophies,
                    'assets/images/gamification/trophy.svg',
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
              StringFormatter.getRoundedStrByRideType(profile.totalDistanceKilometres, RideInfo.distance),
              'km',
            ),
            getInfoWidget(
              Icons.timer,
              StringFormatter.getRoundedStrByRideType(profile.totalDurationMinutes, RideInfo.duration),
              'min',
            ),
            getInfoWidget(
              Icons.speed,
              'ø ${StringFormatter.getRoundedStrByRideType(profile.averageSpeedKmh, RideInfo.averageSpeed)}',
              'km/h',
            ),
            getInfoWidget(
              Icons.arrow_upward,
              StringFormatter.getRoundedStrByRideType(profile.totalElevationGainMetres, RideInfo.elevationGain),
              'm',
            ),
            getInfoWidget(
              Icons.arrow_downward,
              StringFormatter.getRoundedStrByRideType(profile.totalElevationLossMetres, RideInfo.elevationLoss),
              'm',
            ),
          ],
        ),
      ],
    );
  }

  /// Get seperator to seperate header and footer of the card, if necessary.
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
