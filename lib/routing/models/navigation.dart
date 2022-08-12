class NavigationNode {
  final double lon;
  final double lat;
  final double alt;
  final double? distanceToNextSignal;
  final String? signalGroupId;

  const NavigationNode({
    required this.lon,
    required this.lat,
    required this.alt,
    this.distanceToNextSignal,
    this.signalGroupId
  });

  factory NavigationNode.fromJson(Map<String, dynamic> json) {
    return NavigationNode(
      lon: json['lon'].toDouble(),
      lat: json['lat'].toDouble(),
      alt: json['alt'].toDouble(),
      distanceToNextSignal: json['distanceToNextSignal']?.toDouble(),
      signalGroupId: json['signalGroupId'],
    );
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
