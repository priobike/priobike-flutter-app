import 'dart:math';

import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/v2/routing/models/discomfort.dart';
import 'package:priobike/v2/routing/models/sg.dart';
import 'package:priobike/v2/routing/models/navigation.dart';
import 'package:uuid/uuid.dart';

class Route {
  /// A random unique id for this route.
  late String id;

  /// The navigation nodes of the route, as calculated by the routing service.
  final List<NavigationNode> nodes;

  /// The ascend of this route in meters.
  final double ascend;

  /// The descend of this route in meters.
  final double descend;

  /// The duration of this route in seconds.
  final int duration;

  /// The length of this route in meters.
  final double distance;

  /// The (optional) list of traffic lights along the route.
  final List<Sg>? sgs;

  /// The (optional) list of discomforts along the route.
  final List<Discomfort>? discomforts;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Route && other.id == id;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nodes': nodes.map((e) => e.toJson()).toList(),
    'ascend': ascend,
    'descend': descend,
    'duration': duration,
    'distance': distance,
    'sgs': sgs?.map((e) => e.toJson()).toList(),
    'discomforts': discomforts?.map((e) => e.toJson()).toList(),
  };

  factory Route.fromJson(dynamic json) {
    return Route(
      id: json['id'],
      nodes: (json['coordinates'] as List).map((e) => NavigationNode.fromJson(e)).toList(),
      ascend: json['ascend'],
      descend: json['descend'],
      duration: json['duration'],
      distance: json['distance'],
      sgs: (json['sgs'] as List?)?.map((e) => Sg.fromJson(e)).toList(),
      discomforts: (json['discomforts'] as List?)?.map((e) => Discomfort.fromJson(e)).toList(),
    );
  }

  /// Calculate the bounds of this route.
  LatLngBounds get bounds {
    assert(nodes.isNotEmpty);
    var first = nodes.first;
    var s = first.lat,
        n = first.lat,
        w = first.lon,
        e = first.lon;
    for (var i = 1; i < nodes.length; i++) {
      var node = nodes[i];
      s = min(s, node.lat);
      n = max(n, node.lat);
      w = min(w, node.lon);
      e = max(e, node.lon);
    }
    return LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e));
  }

  /// Calculate the padded bounds of this route.
  LatLngBounds get paddedBounds {
    final bounds = this.bounds;
    // Padding is approximately 111m (Approximately 0.001 degrees).
    // See: https://www.usna.edu/Users/oceano/pguth/md_help/html/approx_equivalents.htm
    const pad = 0.001;
    return LatLngBounds(
      southwest: LatLng(bounds.southwest.latitude - pad, bounds.southwest.longitude - pad), 
      northeast: LatLng(bounds.northeast.latitude + pad, bounds.northeast.longitude + pad),
    );
  }

  Route({
    String? id,
    required this.nodes,
    required this.ascend,
    required this.descend, 
    required this.duration, 
    required this.distance,
    this.sgs,
    this.discomforts,
  }) {
    if (id == null) {
      this.id = const Uuid().v4();
    } else {
      this.id = id;
    }
  }
}