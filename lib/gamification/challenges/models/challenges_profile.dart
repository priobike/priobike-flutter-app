/// This profile holds the users' game state for the challenges feature .
class ChallengesProfile {
  /// The xp of the user.
  int xp;

  /// The level of the user.
  int level;

  /// The number of medals the user has.
  int medals;

  /// The number of trophies the user has.
  int trophies;

  /// The number of challenges the user can chose for their daily challenge.
  int dailyChallengeChoices;

  /// The number of challenges the user can chose for their weekly challenge.
  int weeklyChallengeChoices;

  ChallengesProfile({
    this.xp = 0,
    this.level = 0,
    this.medals = 0,
    this.trophies = 0,
    this.dailyChallengeChoices = 1,
    this.weeklyChallengeChoices = 1,
  });

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'level': level,
        'medals': medals,
        'trophies': trophies,
        'dailyChallengeChoices': dailyChallengeChoices,
        'weeklyChallengeChoices': weeklyChallengeChoices,
      };

  factory ChallengesProfile.fromJson(Map<String, dynamic> json) => ChallengesProfile(
        xp: json['xp'],
        level: json['level'],
        medals: json['medals'],
        trophies: json['trophies'],
        dailyChallengeChoices: json['dailyChallengeChoices'],
        weeklyChallengeChoices: json['weeklyChallengeChoices'],
      );
}
