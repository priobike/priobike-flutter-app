import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/models/challenges_profile.dart';
import 'package:priobike/gamification/challenges/models/profile_upgrade.dart';
import 'package:priobike/gamification/challenges/services/challenge_profile_service.dart';
import 'package:priobike/gamification/challenges/views/level_up_dialog.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';
import 'package:priobike/gamification/common/views/level_ring.dart';
import 'package:priobike/gamification/common/models/level.dart';
import 'package:priobike/gamification/common/utils.dart';
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
  late ChallengeProfileService _profileService;

  /// The associated profile service, which is injected by the provider.
  late Profile _routingProfileService;

  /// Controller to animate the trophy icon when a new trophy is gained.
  late final AnimationController _trophiesController;

  /// Controller to animate the medal icon when a new medal is gained.
  late final AnimationController _medalsController;

  /// Animation Controller to controll the ring animation.
  late final AnimationController _ringController;

  bool canLevelUp = false;

  ChallengesProfile? get _profile => _profileService.profile;

  /// Get the current level of the user according to their xp. Returns null if the user hasn't reached a level yet.
  Level get currentLevel {
    if (_profile == null) return levels.first;
    return levels.elementAt(_profile!.level);
  }

  /// Return the next level the user needs to achieve. Returns null, if the user has reached the max level.
  Level? get nextLevel {
    if (_profile == null) return null;
    int level = _profile!.level;
    if (level == levels.length - 1) return null;
    return levels[level + 1];
  }

  void update() => {if (mounted) setState(() {})};

  @override
  void initState() {
    _trophiesController = AnimationController(duration: ShortDuration(), vsync: this);
    _medalsController = AnimationController(duration: ShortDuration(), vsync: this);
    _ringController = AnimationController(vsync: this, duration: ShortDuration(), value: 1);
    _profileService = getIt<ChallengeProfileService>();
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
    _ringController.dispose();
    _profileService.removeListener(updateProfile);
    _routingProfileService.removeListener(update);
    super.dispose();
  }

  /// Bounce animation for the trophy or medal icon.
  Animation<double> getAnimation(var controller) =>
      Tween<double>(begin: 1, end: 2).animate(CurvedAnimation(parent: controller, curve: Curves.bounceIn));

  /// Called when a listener callback of a ChangeNotifier is fired.
  void updateProfile() async {
    // If the user has collected enough xp for the next level, set level up to true and start animation.
    if (nextLevel == null ? false : _profileService.profile!.xp >= nextLevel!.value) {
      _ringController.repeat(reverse: true);
      setState(() => canLevelUp = true);
    }
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
    // Otherwise, just rebuilt the widget.
    else {
      if (mounted) setState(() {});
    }
  }

  Future<void> _showLevelUpDialog() async {
    var result = await showDialog<ProfileUpgrade?>(
      context: context,
      builder: (BuildContext context) {
        return LevelUpDialog(newLevel: nextLevel!);
      },
    );
    return;
    _ringController.stop();
    canLevelUp = false;
    _profileService.levelUp(result);
  }

  /// Returns widget for displaying a trophy count for a trophy with a given icon.
  Widget getTrophyWidget(int number, IconData icon, Animation<double> animation, bool animate) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: animation,
          child: AnimatedContainer(
            duration: ShortDuration(),
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

  @override
  Widget build(BuildContext context) {
    if (_profile == null) return Container();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        AnimatedButton(
          onPressed: nextLevel == null ? null : _showLevelUpDialog,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.fromSize(size: const Size.square(96)),
              if (canLevelUp)
                Container(
                  height: 0,
                  width: 0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: CI.blue.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 40 + _ringController.value * 10,
                      ),
                      BoxShadow(
                        color: Theme.of(context).colorScheme.background,
                        blurRadius: 15,
                        spreadRadius: 40,
                      ),
                    ],
                  ),
                ),
              LevelRing(
                showBorder: false,
                minValue: currentLevel.value.toDouble(),
                maxValue: nextLevel?.value.toDouble() ?? _profile!.xp.toDouble(),
                value: _profile!.xp.toDouble(),
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
                ),
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
                      text: (nextLevel == null) ? '${_profile!.xp} XP' : '${_profile!.xp} / ${nextLevel!.value} XP',
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
                    _profile!.medals,
                    CustomGameIcons.blank_medal,
                    getAnimation(_medalsController),
                    _profileService.medalsChanged,
                  ),
                  getTrophyWidget(
                    _profile!.trophies,
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
