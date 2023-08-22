import 'dart:convert';

class TrackGoals {
  final String trackId;
  final String trackDescription;

  TrackGoals(this.trackId, this.trackDescription);

  Map<String, dynamic> toJson() => {
        'trackId': trackId,
        'trackDescription': trackDescription,
      };

  TrackGoals.fromJson(Map<String, dynamic> json)
      : trackId = json['trackId'],
        trackDescription = json['trackDescription'];
}

class ChallengeGoals {
  final double dailyDistanceGoalMetres;
  final double dailyDurationGoalMinutes;
  final TrackGoals trackGoal;

  ChallengeGoals(this.dailyDistanceGoalMetres, this.dailyDurationGoalMinutes, this.trackGoal);

  Map<String, dynamic> toJson() => {
        'dailyDistanceGoalMetres': dailyDistanceGoalMetres,
        'dailyDurationGoalMinutes': dailyDurationGoalMinutes,
        'trackGoal': jsonEncode(trackGoal.toJson()),
      };

  ChallengeGoals.fromJson(Map<String, dynamic> json)
      : dailyDistanceGoalMetres = json['dailyDistanceGoalMetres'],
        dailyDurationGoalMinutes = json['dailyDurationGoalMinutes'],
        trackGoal = jsonDecode(json['trackGoal']);
}
