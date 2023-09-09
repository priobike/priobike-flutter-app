/// This object holds information about the users daily goals.
class DailyGoals {
  static DailyGoals defaultGoals = DailyGoals(3000, 30);

  /// The users daily distance goals.
  double distanceMetres;

  /// The users daily duration goals.
  double durationMinutes;

  DailyGoals(this.distanceMetres, this.durationMinutes);

  Map<String, dynamic> toJson() => {
        'distanceMetres': distanceMetres,
        'durationMinutes': durationMinutes,
      };

  DailyGoals.fromJson(Map<String, dynamic> json)
      : distanceMetres = json['distanceMetres'],
        durationMinutes = json['durationMinutes'];
}
