/// This class holds the relevant data of a user.
class UserProfile {
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

  /// The number of silver trophies the user has.
  int silverTrophies;

  /// The number of gold trophies the user has.
  int goldTrophies;

  UserProfile({
    this.totalDistanceKilometres = 0,
    this.totalDurationMinutes = 0,
    this.totalElevationGainMetres = 0,
    this.totalElevationLossMetres = 0,
    this.xp = 0,
    this.silverTrophies = 0,
    this.goldTrophies = 0,
    required this.username,
    required this.joinDate,
  }) : averageSpeedKmh = totalDurationMinutes == 0 ? 0 : (totalDistanceKilometres / totalDurationMinutes) * 3.6;

  Map<String, dynamic> toJson() => {
        'totalDistanceMetres': totalDistanceKilometres,
        'totalDurationSeconds': totalDurationMinutes,
        'totalElevationGainMetres': totalElevationGainMetres,
        'totalElevationLossMetres': totalElevationLossMetres,
        'xp': xp,
        'silverTrophies': silverTrophies,
        'goldTrophies': goldTrophies,
        'username': username,
        'joinDate': joinDate.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        totalDistanceKilometres: json['totalDistanceMetres'],
        totalDurationMinutes: json['totalDistanceMetres'],
        totalElevationGainMetres: json['totalElevationGainMetres'],
        totalElevationLossMetres: json['totalElevationLossMetres'],
        xp: json['xp'],
        silverTrophies: json['silverTrophies'],
        goldTrophies: json['goldTrophies'],
        username: json['username'],
        joinDate: DateTime.parse(json['joinDate']),
      );
}
