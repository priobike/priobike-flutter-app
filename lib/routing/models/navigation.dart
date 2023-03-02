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

class NavigationNodeMultiLane {
  final double lon;
  final double lat;
  final double alt;

  const NavigationNodeMultiLane({required this.lon, required this.lat, required this.alt});

  factory NavigationNodeMultiLane.fromJson(Map<String, dynamic> json) => NavigationNodeMultiLane(
        lon: json['lon'].toDouble(),
        lat: json['lat'].toDouble(),
        alt: json['alt'].toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'lon': lon,
        'lat': lat,
        'alt': alt,
      };

  factory NavigationNodeMultiLane.fromNavigationNode(NavigationNode node) => NavigationNodeMultiLane(
        lon: node.lon,
        lat: node.lat,
        alt: node.alt,
      );
}
