class NavigationNode {
  final double lon;
  final double lat;
  final double alt;
  final double? distanceToNextSignal;
  final String? signalGroupId;

  const NavigationNode(
      {required this.lon, required this.lat, required this.alt, this.distanceToNextSignal, this.signalGroupId});

  factory NavigationNode.fromJson(Map<String, dynamic> json) => NavigationNode(
        lon: json['lon'].toDouble(),
        lat: json['lat'].toDouble(),
        alt: json['alt'].toDouble(),
        distanceToNextSignal: json['distanceToNextSignal']?.toDouble(),
        signalGroupId: json['signalGroupId'],
      );

  Map<String, dynamic> toJson() => {
        'lon': lon,
        'lat': lat,
        'alt': alt,
        'distanceToNextSignal': distanceToNextSignal,
        'signalGroupId': signalGroupId,
      };
}
