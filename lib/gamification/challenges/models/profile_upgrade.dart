import 'package:priobike/gamification/challenges/models/level.dart';

/// The possible upgrade types, which determine what to do, if an update is activated by the user.
enum ProfileUpgradeType {
  moreChallengeTypes,
  addWeeklyChallenge,
  addDailyChoice,
  addWeeklyChoice,
  highestLevel,
}

/// An upgrade which can be activated when the users reaches a certain level to enhance certain profile values.
class ProfileUpgrade {
  /// Textual description of the upgrade.
  final String description;

  /// Type of upgrade.
  final ProfileUpgradeType type;

  ProfileUpgrade(this.description, this.type);

  Map<String, dynamic> toJson() => {
        'description': description,
        'type': type.index,
      };

  ProfileUpgrade.fromJson(Map<String, dynamic> json)
      : description = json['description'],
        type = ProfileUpgradeType.values.elementAt(json['type']);
}

List<ProfileUpgrade> getUpgradesForLevel(int level) {
  if (level == 1) {
    return [
      ProfileUpgrade(
        'Du hast 3 neue Arten von Tageschallenges freigeschaltet! Setze Dir persönliche Tages- und Routenziele, um sie auszuprobieren.',
        ProfileUpgradeType.moreChallengeTypes,
      )
    ];
  } else if (level == 2) {
    return [
      ProfileUpgrade(
        'Du kannst ab jetzt an den Wochenchallenges teilnehmen!',
        ProfileUpgradeType.addWeeklyChallenge,
      )
    ];
  } else if (level == 3) {
    return [
      ProfileUpgrade(
        'Ab jetzt kannst Du Deine Tageschallenge aus 2 Vorschlägen auswählen.',
        ProfileUpgradeType.addDailyChoice,
      )
    ];
  } else if (level == 4) {
    return [
      ProfileUpgrade(
        'Ab jetzt kannst Du Deine Wochenchallenge aus 2 Vorschlägen auswählen.',
        ProfileUpgradeType.addWeeklyChoice,
      )
    ];
  } else if (level == levels.length - 1) {
    return [
      ProfileUpgrade(
        'Herzlichen Glückwunsch, Du hast das höchste Level erreich!',
        ProfileUpgradeType.highestLevel,
      ),
    ];
  } else {
    return [
      ProfileUpgrade(
        'Erhalte eine extra Auswahlmöglichkeit für die täglichen Challenges.',
        ProfileUpgradeType.addDailyChoice,
      ),
      ProfileUpgrade(
        'Erhalte eine extra Auswahlmöglichkeit für die wöchentlichen Challenges.',
        ProfileUpgradeType.addWeeklyChoice,
      ),
    ];
  }
}
