/// This class holds the relevant data of a user.
class UserProfile {
  /// The total distance covered by a user while using the app.
  double totalDistanceMetres;

  /// The total duration the user drove while using the app.
  double totalDurationSeconds;

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

  UserProfile({
    this.totalDistanceMetres = 0,
    this.totalDurationSeconds = 0,
    this.totalElevationGainMetres = 0,
    this.totalElevationLossMetres = 0,
    required this.username,
    required String parsedJoinDate,
  })  : joinDate = DateTime.parse(parsedJoinDate),
        averageSpeedKmh = totalDurationSeconds == 0 ? 0 : (totalDistanceMetres / totalDurationSeconds) * 3.6;
}
