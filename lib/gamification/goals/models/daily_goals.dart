/// This object holds information about the users daily goals.
class DailyGoals {
  static DailyGoals get defaultGoals => DailyGoals(3000, 30, List.filled(DateTime.daysPerWeek, false));

  /// The users daily distance goals.
  double distanceMetres;

  /// The users daily duration goals.
  double durationMinutes;

  /// A list which holds 7 bools which determinem whether the users wants to reach their dailay goals on a day.
  List<bool> weekdays;

  /// Returns the number of weekdays where the goals are activated.
  int get numOfDays => weekdays.where((day) => day).length;

  DailyGoals(this.distanceMetres, this.durationMinutes, this.weekdays);

  Map<String, dynamic> toJson() => {
        'distanceMetres': distanceMetres,
        'durationMinutes': durationMinutes,
        'weekdays': weekdays,
      };

  DailyGoals.fromJson(Map<String, dynamic> json)
      : distanceMetres = json['distanceMetres'],
        durationMinutes = json['durationMinutes'],
        weekdays = (json['weekdays'] as List<dynamic>).map((v) => v as bool).toList();
}
