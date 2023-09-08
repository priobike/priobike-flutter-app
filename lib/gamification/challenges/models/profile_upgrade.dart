enum ProfileUpgradeType {
  addDailyChoice,
  addWeeklyChoice,
  addDailyChallenge,
  addWeeklyChallenge,
}

class ProfileUpgrade {
  final String id;

  final String description;

  final int levelToActivate;

  final ProfileUpgradeType type;

  ProfileUpgrade(this.id, this.description, this.levelToActivate, this.type);

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'levelToActivate': levelToActivate,
        'type': type.index,
      };

  ProfileUpgrade.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        description = json['description'],
        levelToActivate = json['levelToActivate'],
        type = ProfileUpgradeType.values.elementAt(json['type']);

  static List<ProfileUpgrade> upgrades = [
    ProfileUpgrade(
      '0',
      'Ab jetzt kannst du deine Tageschallenge aus 2 Vorschlägen auswählen.',
      1,
      ProfileUpgradeType.addDailyChoice,
    ),
    ProfileUpgrade(
      '1',
      'Ab jetzt kannst du deine Wochenchallenge aus 2 Vorschlägen auswählen.',
      2,
      ProfileUpgradeType.addWeeklyChoice,
    ),
    ProfileUpgrade(
      '2',
      'Erhalte eine extra Auswahlmöglichkeit für die täglichen Challenges.',
      3,
      ProfileUpgradeType.addDailyChoice,
    ),
    ProfileUpgrade(
      '3',
      'Erhalte eine extra Auswahlmöglichkeit für die wöchentlichen Challenges.',
      3,
      ProfileUpgradeType.addWeeklyChoice,
    ),
  ];
}
