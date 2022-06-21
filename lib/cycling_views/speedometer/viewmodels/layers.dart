import 'package:mapbox_gl/mapbox_gl.dart';

/// A map layer which marks the route on the map.
class RouteLayer extends LineOptions {
  /// Create a new route layer.
  RouteLayer({ required List<LatLng> points }) : super(
    geometry: points,
    lineWidth: 15.0,
    lineColor: "#1e90ff",
    lineJoin: "round",
  );
}