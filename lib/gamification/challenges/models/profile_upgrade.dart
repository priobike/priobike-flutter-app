import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';

/// The possible upgrade types, which determine what to do, if an update is activated by the user.
enum ProfileUpgradeType {
  addDailyChoice,
  addWeeklyChoice,
  addDailyChallenge,
  addWeeklyChallenge,
}

/// An upgrade which can be activated when the users reaches a certain level to enhance certain profile values.
class ProfileUpgrade {
  /// Unique id for the upgrade.
  final String id;

  /// Textual description of the upgrade.
  final String description;

  /// Level needet to activate this upgrade.
  final int levelToActivate;

  /// Type of upgrade.
  final ProfileUpgradeType type;

  /// Icon describing the upgrades.
  final IconData icon;

  ProfileUpgrade(this.id, this.description, this.levelToActivate, this.type, this.icon);

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'levelToActivate': levelToActivate,
        'type': type.index,
        'icon': icon.codePoint,
      };

  ProfileUpgrade.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        description = json['description'],
        levelToActivate = json['levelToActivate'],
        type = ProfileUpgradeType.values.elementAt(json['type']),
        icon = IconData(json['icon'], fontFamily: 'MaterialIcons');

  /// List of possible upgrades.
  static List<ProfileUpgrade> upgrades = [
    ProfileUpgrade(
      '0',
      'Ab jetzt kannst du deine Tageschallenge aus 2 Vorschlägen auswählen.',
      1,
      ProfileUpgradeType.addDailyChoice,
      CustomGameIcons.blank_medal,
    ),
    ProfileUpgrade(
      '1',
      'Ab jetzt kannst du deine Wochenchallenge aus 2 Vorschlägen auswählen.',
      2,
      ProfileUpgradeType.addWeeklyChoice,
      CustomGameIcons.blank_trophy,
    ),
    ProfileUpgrade(
      '2',
      'Erhalte eine extra Auswahlmöglichkeit für die täglichen Challenges.',
      3,
      ProfileUpgradeType.addDailyChoice,
      CustomGameIcons.blank_medal,
    ),
    ProfileUpgrade(
      '3',
      'Erhalte eine extra Auswahlmöglichkeit für die wöchentlichen Challenges.',
      3,
      ProfileUpgradeType.addWeeklyChoice,
      CustomGameIcons.blank_trophy,
    ),
  ];
}
