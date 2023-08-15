class UserProfile {
  double totalDistanceMetres;
  double totalDurationSeconds;
  double totalElevationGainMetres;
  double totalElevationLossMetres;
  double averageSpeedKmh;
  DateTime joinDate;
  List<String> prefs;
  String username;

  UserProfile({
    this.totalDistanceMetres = 0,
    this.totalDurationSeconds = 0,
    this.totalElevationGainMetres = 0,
    this.totalElevationLossMetres = 0,
    required this.username,
    required String parsedJoinDate,
    this.prefs = const [],
  })  : joinDate = DateTime.parse(parsedJoinDate),
        averageSpeedKmh = (totalDistanceMetres / totalDistanceMetres) * 3.6;
}
