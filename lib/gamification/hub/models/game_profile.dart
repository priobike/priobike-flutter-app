/// This class holds the relevant game data of a user.
class GameProfile {
  /// The total distance covered by a user while using the app.
  double totalDistanceKilometres;

  /// The total duration the user drove while using the app.
  double totalDurationMinutes;

  /// The total elevation gain the user covered.
  double totalElevationGainMetres;

  /// The total elevation loss the user covered.
  double totalElevationLossMetres;

  /// The average speed the user covered the total distance with.
  double averageSpeedKmh;

  /// The exact time point the user profile was created.
  DateTime joinDate;

  /// The users' username.
  String username;

  /// The xp of the user.
  int xp;

  /// The number of medals the user has.
  int medals;

  /// The number of trophies the user has.
  int trophies;

  GameProfile({
    this.totalDistanceKilometres = 0,
    this.totalDurationMinutes = 0,
    this.totalElevationGainMetres = 0,
    this.totalElevationLossMetres = 0,
    this.xp = 0,
    this.medals = 0,
    this.trophies = 0,
    required this.username,
    required this.joinDate,
  }) : averageSpeedKmh = totalDurationMinutes == 0 ? 0 : (totalDistanceKilometres / totalDurationMinutes) * 3.6;

  Map<String, dynamic> toJson() => {
        'totalDistanceMetres': totalDistanceKilometres,
        'totalDurationSeconds': totalDurationMinutes,
        'totalElevationGainMetres': totalElevationGainMetres,
        'totalElevationLossMetres': totalElevationLossMetres,
        'xp': xp,
        'medals': medals,
        'trophies': trophies,
        'username': username,
        'joinDate': joinDate.toIso8601String(),
      };

  factory GameProfile.fromJson(Map<String, dynamic> json) => GameProfile(
        totalDistanceKilometres: json['totalDistanceMetres'],
        totalDurationMinutes: json['totalDistanceMetres'],
        totalElevationGainMetres: json['totalElevationGainMetres'],
        totalElevationLossMetres: json['totalElevationLossMetres'],
        xp: json['xp'],
        medals: json['medals'],
        trophies: json['trophies'],
        username: json['username'],
        joinDate: DateTime.parse(json['joinDate']),
      );
}
