import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/views/level_ring.dart';
import 'package:priobike/gamification/common/models/level.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/services/profile_service.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/main.dart';

/// This view displays the basic info about the users game profile. This can contain their achieved game rewards and
/// their overall statistics of all registered rides. But what exactly is displayed depends on the users'
/// enabled gamification features.
class GameProfileView extends StatefulWidget {
  const GameProfileView({Key? key}) : super(key: key);

  @override
  State<GameProfileView> createState() => _GameProfileViewState();
}

class _GameProfileViewState extends State<GameProfileView> with TickerProviderStateMixin {
  /// The service which manages and provides the user profile.
  late GameProfileService _profileService;

  /// The associated profile service, which is injected by the provider.
  late Profile _routingProfileService;

  /// Controller to animate the trophy icon when a new trophy is gained.
  late final AnimationController _trophiesController;

  /// Controller to animate the medal icon when a new medal is gained.
  late final AnimationController _medalsController;

  /// Animation Controller to controll the ring animation.
  late final AnimationController _ringController;

  bool canLevelUp = false;

  /// Bounce animation for the trophy or medal icon.
  Animation<double> getAnimation(var controller) =>
      Tween<double>(begin: 1, end: 2).animate(CurvedAnimation(parent: controller, curve: Curves.bounceIn));

  void update() {
    if (mounted) setState(() {});
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void updateProfile() async {
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
    // If the user has collected enough xp for the next level, set level up to true and start animation.
    if (nextLevel == null ? false : _profileService.profile!.xp >= nextLevel!.value) {
      _ringController.repeat(reverse: true);
      setState(() => canLevelUp = true);
    }
  }

  @override
  void initState() {
    _trophiesController = AnimationController(duration: ShortDuration(), vsync: this);
    _medalsController = AnimationController(duration: ShortDuration(), vsync: this);
    _ringController = AnimationController(vsync: this, duration: ShortDuration(), value: 1);
    _profileService = getIt<GameProfileService>();
    _profileService.addListener(updateProfile);
    _routingProfileService = getIt<Profile>();
    _routingProfileService.addListener(update);
    _ringController.addListener(update);
    // If the user has collected enough xp for the next level, set level up to true and start animation.
    if (nextLevel == null ? false : _profileService.profile!.xp >= nextLevel!.value) {
      _ringController.repeat(reverse: true);
      canLevelUp = true;
    }
    super.initState();
  }

  @override
  void dispose() {
    _medalsController.dispose();
    _trophiesController.dispose();
    _profileService.removeListener(updateProfile);
    _routingProfileService.removeListener(update);
    _ringController.removeListener(update);
    super.dispose();
  }

  /// Get the current level of the user according to their xp. Returns null if the user hasn't reached a level yet.
  Level get currentLevel => levels.elementAt(_profileService.profile!.level);

  /// Return the next level the user needs to achieve. Returns null, if the user has reached the max level.
  Level? get nextLevel {
    int level = _profileService.profile!.level;
    if (level == levels.length - 1) return null;
    return levels[level + 1];
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

  /// Get card header without a game state.
  Widget getNoRewardsHeader(var profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BoldSubHeader(
          text: 'Deine Gesamtstatistiken',
          context: context,
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var profile = _profileService.profile!;
    var lightMode = Theme.of(context).brightness == Brightness.light;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        GestureDetector(
          onTap: () {},
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (canLevelUp)
                Container(
                  height: 0,
                  width: 0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: CI.blue.withOpacity(lightMode ? 0.4 : 0.25),
                        blurRadius: 10,
                        spreadRadius: 50 + _ringController.value * 10,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 50 + _ringController.value * 10,
                      ),
                      BoxShadow(
                        color: Theme.of(context).colorScheme.background,
                        blurRadius: 15,
                        spreadRadius: 35 + _ringController.value * 5,
                      ),
                    ],
                  ),
                ),
              LevelRing(
                showBorder: false,
                minValue: currentLevel.value.toDouble(),
                maxValue: nextLevel?.value.toDouble() ?? profile.xp.toDouble(),
                value: profile.xp.toDouble(),
                iconColor: (currentLevel == levels[0])
                    ? Theme.of(context).colorScheme.onBackground.withOpacity(0.25)
                    : currentLevel.color,
                icon: canLevelUp ? null : _routingProfileService.bikeType?.icon() ?? Icons.pedal_bike,
                ringSize: 96,
                ringColor: canLevelUp ? CI.blue : nextLevel?.color ?? currentLevel.color,
              ),
              if (canLevelUp)
                Column(
                  children: [
                    BoldContent(text: 'Level', context: context, color: CI.blue),
                    BoldContent(text: 'Up', context: context, color: CI.blue),
                  ],
                )
            ],
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
                    BoldSubHeader(text: currentLevel.title, context: context),
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
                    CustomGameIcons.blank_medal,
                    getAnimation(_medalsController),
                    _profileService.medalsChanged,
                  ),
                  getTrophyWidget(
                    profile.trophies,
                    CustomGameIcons.blank_trophy,
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
}
