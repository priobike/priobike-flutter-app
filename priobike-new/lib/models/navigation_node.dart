class NavigationNode {
  double lon = 0;
  double lat = 0;
  double alt = 0;
  double? distanceToNextSignal;
  String? signalGroupId;

  NavigationNode(
      {required this.lon,
      required this.lat,
      required this.alt,
      required this.distanceToNextSignal,
      required this.signalGroupId});

  NavigationNode.fromJson(Map<String, dynamic> json) {
    lon = json['lon'].toDouble();
    lat = json['lat'].toDouble();
    alt = json['alt'].toDouble();
    distanceToNextSignal = json['distanceToNextSignal']?.toDouble();
    signalGroupId = json['signalGroupId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lon'] = lon;
    data['lat'] = lat;
    data['alt'] = alt;
    data['distanceToNextSignal'] = distanceToNextSignal;
    data['signalGroupId'] = signalGroupId;
    return data;
  }
}
