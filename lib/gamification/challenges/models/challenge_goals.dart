import 'dart:convert';

/// This object holds information about the users challenge goals.
class ChallengeGoals {
  /// The users daily distance goals.
  final double dailyDistanceGoalMetres;

  /// The users daily duration goals.
  final double dailyDurationGoalMinutes;

  /// Goals for a specific route of the user.
  final RouteGoals? routeGoal;

  ChallengeGoals(this.dailyDistanceGoalMetres, this.dailyDurationGoalMinutes, this.routeGoal);

  Map<String, dynamic> toJson() => {
        'dailyDistanceGoalMetres': dailyDistanceGoalMetres,
        'dailyDurationGoalMinutes': dailyDurationGoalMinutes,
        'routeGoal': routeGoal == null ? null : jsonEncode(routeGoal!.toJson()),
      };

  ChallengeGoals.fromJson(Map<String, dynamic> json)
      : dailyDistanceGoalMetres = json['dailyDistanceGoalMetres'],
        dailyDurationGoalMinutes = json['dailyDurationGoalMinutes'],
        routeGoal = json['routeGoal'] == null ? null : RouteGoals.fromJson(jsonDecode(json['routeGoal']));
}

/// This object describes user goals for a specific route.
class RouteGoals {
  /// The unique id of the route to identify it.
  final String routeID;

  /// The name of the route.
  final String trackName;

  /// The number of times, the user wants to drive this route.
  final int perWeek;

  RouteGoals(this.routeID, this.trackName, this.perWeek);

  Map<String, dynamic> toJson() => {
        'routeID': routeID,
        'trackName': trackName,
        'perWeek': perWeek,
      };

  RouteGoals.fromJson(Map<String, dynamic> json)
      : routeID = json['routeID'],
        trackName = json['trackName'],
        perWeek = json['perWeek'];
}