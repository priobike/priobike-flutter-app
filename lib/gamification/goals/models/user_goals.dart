
import 'dart:convert';

/// This object holds information about the users challenge goals.
class UserGoals {
  static UserGoals defaultGoals = UserGoals(3000, 30, null);

  /// The users daily distance goals.
  double dailyDistanceGoalMetres;

  /// The users daily duration goals.
  double dailyDurationGoalMinutes;

  /// Goals for a specific route of the user.
  RouteGoals? routeGoal;

  UserGoals(this.dailyDistanceGoalMetres, this.dailyDurationGoalMinutes, this.routeGoal);

  Map<String, dynamic> toJson() => {
        'dailyDistanceGoalMetres': dailyDistanceGoalMetres,
        'dailyDurationGoalMinutes': dailyDurationGoalMinutes,
        'routeGoal': routeGoal == null ? null : jsonEncode(routeGoal!.toJson()),
      };

  UserGoals.fromJson(Map<String, dynamic> json)
      : dailyDistanceGoalMetres = json['dailyDistanceGoalMetres'],
        dailyDurationGoalMinutes = json['dailyDurationGoalMinutes'],
        routeGoal = json['routeGoal'] == null ? null : RouteGoals.fromJson(jsonDecode(json['routeGoal']));
}

/// This object describes user goals for a specific route.
class RouteGoals {
  /// The unique id of the route to identify it.
  String routeID;

  /// The name of the route.
  String trackName;

  /// The number of times, the user wants to drive this route.
  int perWeek;

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
