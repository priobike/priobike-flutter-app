import 'package:mapbox_gl/mapbox_gl.dart';

/// A map layer which marks the route on the map.
class RouteLayer extends LineOptions {
  /// Create a new route layer.
  RouteLayer({ required List<LatLng> points }) : super(
    geometry: points,
    lineWidth: 7.0,
    lineColor: "#0094FF",
    lineJoin: "round",
  );
}

/// A map layer which marks an alternative route on the map.
class AltRouteLayer extends LineOptions {
  /// Create a new alt route layer.
  AltRouteLayer({ required List<LatLng> points }) : super(
    geometry: points,
    lineWidth: 7.0,
    lineColor: "#868686",
    lineJoin: "round",
  );
}

/// A map layer which marks a discomfort section on the map.
class DiscomfortSectionLayer extends LineOptions {
  /// Create a new discomfort section layer.
  DiscomfortSectionLayer({ required List<LatLng> points }) : super(
    geometry: points,
    lineWidth: 7.0,
    lineColor: "#FF0000",
    lineJoin: "round",
  );
}