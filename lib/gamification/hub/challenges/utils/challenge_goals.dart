import 'dart:convert';

class RouteGoals {
  final String routeID;
  final String trackDescription;
  final int perWeek;

  RouteGoals(this.routeID, this.trackDescription, this.perWeek);

  Map<String, dynamic> toJson() => {
        'routeID': routeID,
        'trackDescription': trackDescription,
        'perWeek': perWeek,
      };

  RouteGoals.fromJson(Map<String, dynamic> json)
      : routeID = json['routeID'],
        trackDescription = json['trackDescription'],
        perWeek = json['perWeek'];
}

class ChallengeGoals {
  final double dailyDistanceGoalMetres;
  final double dailyDurationGoalMinutes;
  final RouteGoals? trackGoal;

  ChallengeGoals(this.dailyDistanceGoalMetres, this.dailyDurationGoalMinutes, this.trackGoal);

  Map<String, dynamic> toJson() => {
        'dailyDistanceGoalMetres': dailyDistanceGoalMetres,
        'dailyDurationGoalMinutes': dailyDurationGoalMinutes,
        'trackGoal': trackGoal == null ? null : jsonEncode(trackGoal!.toJson()),
      };

  ChallengeGoals.fromJson(Map<String, dynamic> json)
      : dailyDistanceGoalMetres = json['dailyDistanceGoalMetres'],
        dailyDurationGoalMinutes = json['dailyDurationGoalMinutes'],
        trackGoal = jsonDecode(json['trackGoal']);
}
