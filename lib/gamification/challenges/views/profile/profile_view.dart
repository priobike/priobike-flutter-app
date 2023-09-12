import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/models/challenges_profile.dart';
import 'package:priobike/gamification/challenges/models/profile_upgrade.dart';
import 'package:priobike/gamification/challenges/services/challenges_profile_service.dart';
import 'package:priobike/gamification/challenges/views/profile/lvl_up_dialog.dart';
import 'package:priobike/gamification/challenges/views/profile/multiple_upgrades_lvl_up.dart.dart';
import 'package:priobike/gamification/challenges/views/profile/single_upgrade_lvl_up.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';
import 'package:priobike/gamification/common/views/progress_ring.dart';
import 'package:priobike/gamification/common/models/level.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/main.dart';

/// This view displays the users game state for the challenge feature and provides them with the option to
/// upgrade to the next level, if the current level is finished.
class GameProfileView extends StatefulWidget {
  const GameProfileView({Key? key}) : super(key: key);

  @override
  State<GameProfileView> createState() => _GameProfileViewState();
}

class _GameProfileViewState extends State<GameProfileView> with TickerProviderStateMixin {
  /// The service which manages and provides the user profile.
  late ChallengesProfileService _profileService;

  /// Controller to animate the trophy icon when a new trophy is gained.
  late final AnimationController _trophiesController;

  /// Controller to animate the medal icon when a new medal is gained.
  late final AnimationController _medalsController;

  /// Animation Controller to controll the animation of the level ring, when the user can level up.
  late final AnimationController _ringController;

  /// The users profile for the challenges feature.
  ChallengesProfile? get _profile => _profileService.profile;

  /// Get the current level of the user as a Level object.
  Level get _currentLevel {
    if (_profile == null) return levels.first;
    return levels.elementAt(_profile!.level);
  }

  /// Return the next level the user needs to achieve. Returns null, if the user has reached the max level.
  Level? get _nextLevel {
    if (_profile == null) return null;
    int level = _profile!.level;
    if (level == levels.length - 1) return null;
    return levels[level + 1];
  }

  /// The progress of the user for the next level to reach, as a value between 0 and 1.
  double get _levelProgress {
    if (_nextLevel == null || _profile == null) return 1;
    var progress = (_profile!.xp - _currentLevel.value) / (_nextLevel!.value - _currentLevel.value);
    return min(1, max(0, progress));
  }

  bool get canLevelUp => _nextLevel != null && _profileService.profile!.xp >= _nextLevel!.value;

  @override
  void initState() {
    _trophiesController = AnimationController(duration: MediumDuration(), vsync: this);
    _medalsController = AnimationController(duration: MediumDuration(), vsync: this);
    _ringController = AnimationController(vsync: this, duration: MediumDuration(), value: 1);
    _profileService = getIt<ChallengesProfileService>();
    _profileService.addListener(updateProfile);
    _ringController.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _medalsController.dispose();
    _trophiesController.dispose();
    _ringController.dispose();
    _profileService.removeListener(updateProfile);
    super.dispose();
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  /// Called when the users challenge profile changes.
  void updateProfile() async {
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

  /// Bounce animation for the trophy or medal icon.
  Animation<double> _getAnimation(var controller) =>
      Tween<double>(begin: 1, end: 2).animate(CurvedAnimation(parent: controller, curve: Curves.bounceIn));

  /// Opaen level up dialog according to the number of possible upgrades the user can apply with the level up.
  Future<void> _showLevelUpDialog() async {
    if (_nextLevel == null) return;
    var openUpgrades = _profileService.allowedUpgrades;
    var result = await showDialog<ProfileUpgrade?>(
      context: context,
      barrierDismissible: openUpgrades.length <= 1,
      builder: (BuildContext context) {
        if (openUpgrades.isEmpty) {
          return LevelUpDialog(newLevel: _nextLevel!);
        } else if (openUpgrades.length == 1) {
          return SingleUpgradeLvlUpDialog(newLevel: _nextLevel!, upgrade: openUpgrades.first);
        } else {
          return MultipleUpgradesLvlUpDialog(newLevel: _nextLevel!, upgrades: openUpgrades);
        }
      },
    );
    _profileService.levelUp(result);
  }

  /// Returns widget for displaying the count of a collected virtual reward.
  Widget _getRewardWidget(int number, IconData icon, Animation<double> animation, bool animate) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: animation,
          child: AnimatedContainer(
            duration: MediumDuration(),
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
              color: CI.blue, //animate ? CI.blue : Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
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

  Widget _getRingContent() {
    if (canLevelUp) {
      return ScaleTransition(
        scale:
            Tween<double>(begin: 1, end: 1.3).animate(CurvedAnimation(parent: _ringController, curve: Curves.easeOut)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BoldContent(
              text: 'Level',
              context: context,
              color: _nextLevel!.color,
              height: 1,
            ),
            BoldSubHeader(
              text: 'Up',
              context: context,
              color: _nextLevel!.color,
              height: 1,
            ),
          ],
        ),
      );
    } else if (!canLevelUp && _nextLevel != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SmallVSpace(),
          BoldContent(
            text: 'Level',
            context: context,
            color: Color.alphaBlend(
              Theme.of(context).colorScheme.onBackground.withOpacity(0.1 * (1 - _levelProgress)),
              _nextLevel!.color.withOpacity(_levelProgress),
            ),
            height: 1,
          ),
          Header(
            text: '${levels.indexOf(_nextLevel!)}',
            context: context,
            color: Color.alphaBlend(
              Theme.of(context).colorScheme.onBackground.withOpacity(0.1 * (1 - _levelProgress)),
              _nextLevel!.color.withOpacity(_levelProgress),
            ),
          ),
        ],
      );
    } else {
      return Icon(
        Icons.directions_bike,
        color: _currentLevel.color,
        size: 56,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) return Container();
    if (canLevelUp && !_ringController.isAnimating) {
      _ringController.repeat(reverse: true);
    } else if (!canLevelUp && _ringController.isAnimating) {
      _ringController.stop();
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        OnTabAnimation(
          onPressed: canLevelUp && _nextLevel != null ? _showLevelUpDialog : null,
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
                    boxShadow: Theme.of(context).brightness == Brightness.dark
                        ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 35 + _ringController.value * 10,
                            ),
                            BoxShadow(
                              color: Theme.of(context).colorScheme.background,
                              blurRadius: 15,
                              spreadRadius: 45,
                            ),
                          ]
                        : [],
                  ),
                ),
              if (_nextLevel == null)
                Container(
                  height: 0,
                  width: 0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _currentLevel.color.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 40,
                      ),
                      BoxShadow(
                        color: Theme.of(context).colorScheme.background,
                        blurRadius: 15,
                        spreadRadius: 40,
                      ),
                    ],
                  ),
                ),
              ProgressRing(
                progress: _levelProgress,
                ringSize: 96,
                ringColor: _nextLevel?.color ?? _currentLevel.color,
                content: _getRingContent(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BoldContent(
                  text: _currentLevel.title,
                  context: context,
                ),
                Content(
                  text: (_nextLevel == null) ? '${_profile!.xp} XP' : '${_profile!.xp} / ${_nextLevel!.value} XP',
                  context: context,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                ),
                Expanded(child: Container()),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OnTabAnimation(
                      onPressed: () => AppDatabase.instance.challengeDao.createObject(
                        ChallengesCompanion.insert(
                          xp: 25,
                          startTime: DateTime(2023),
                          closingTime: DateTime(2023),
                          description: '',
                          target: 0,
                          progress: 100,
                          isWeekly: false,
                          isOpen: false,
                          type: 0,
                        ),
                      ),
                      child: _getRewardWidget(
                        _profile!.medals,
                        CustomGameIcons.blank_medal,
                        _getAnimation(_medalsController),
                        _profileService.medalsChanged,
                      ),
                    ),
                    OnTabAnimation(
                      onPressed: () => AppDatabase.instance.challengeDao.createObject(
                        ChallengesCompanion.insert(
                          xp: 100,
                          startTime: DateTime(2023),
                          closingTime: DateTime(2023),
                          description: '',
                          target: 0,
                          progress: 100,
                          isWeekly: true,
                          isOpen: false,
                          type: 0,
                        ),
                      ),
                      child: _getRewardWidget(
                        _profile!.trophies,
                        CustomGameIcons.blank_trophy,
                        _getAnimation(_trophiesController),
                        _profileService.trophiesChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
