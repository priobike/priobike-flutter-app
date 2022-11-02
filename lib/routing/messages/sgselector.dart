import 'package:priobike/routing/models/crossing.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/routing/models/sg.dart';

class SGSelectorPosition {
  /// The latitude of the position.
  final double lat;

  /// The longitude of the position.
  final double lon;

  /// The altitude of the position.
  final double alt;

  const SGSelectorPosition({
    required this.lat,
    required this.lon,
    required this.alt,
  });

  factory SGSelectorPosition.fromJson(Map<String, dynamic> json) =>
      SGSelectorPosition(
        lat: json['lat'].toDouble(),
        lon: json['lon'].toDouble(),
        alt: json['alt'].toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'alt': alt,
      };
}

class SGSelectorRequest {
  /// The computed route, containing coordinates with altitude.
  final List<SGSelectorPosition> route;

  const SGSelectorRequest({required this.route});

  Map<String, dynamic> toJson() => {
        'route': route.map((v) => v.toJson()).toList(),
      };

  factory SGSelectorRequest.fromJson(Map<String, dynamic> json) {
    return SGSelectorRequest(
      route: (json['route'] as List)
          .map((e) => SGSelectorPosition.fromJson(e))
          .toList(),
    );
  }
}

class SGSelectorResponse {
  /// The list of navigation nodes.
  final List<NavigationNode> route;

  /// The signal groups of the route..
  final Map<String, Sg> signalGroups;

  /// The crossings of the route.
  final List<Crossing> crossings;

  SGSelectorResponse(
      {required this.route,
      required this.signalGroups,
      required this.crossings});

  factory SGSelectorResponse.fromJson(Map<String, dynamic> json) =>
      SGSelectorResponse(
        route: (json['route'] as List)
            .map((e) => NavigationNode.fromJson(e))
            .toList(),
        signalGroups: (json['signalGroups'] as Map<String, dynamic>)
            .map((k, e) => MapEntry(k, Sg.fromJson(e))),
        crossings: (json['crossings'] as List)
            .map((e) => Crossing.fromJson(e))
            .toList(),
      );
}
