/// This object describes user goals for a specific route.
class RouteGoals {
  /// The unique id of the route to identify it.
  String routeID;

  /// The name of the route.
  String routeName;

  /// A bool which should hold 7 bool values, which determine whether the users wants to drive the route on a day.
  List<bool> weekdays;

  RouteGoals(this.routeID, this.routeName, this.weekdays);

  int get numOfDays => weekdays.where((day) => day).length;

  Map<String, dynamic> toJson() => {
        'routeID': routeID,
        'trackName': routeName,
        'weekdays': weekdays,
      };

  RouteGoals.fromJson(Map<String, dynamic> json)
      : routeID = json['routeID'],
        routeName = json['trackName'],
        weekdays = (json['weekdays'] as List<dynamic>).map((v) => v as bool).toList();
}
