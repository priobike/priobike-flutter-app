import 'package:mapbox_gl/mapbox_gl.dart';

/// A line layer for the route.
class RouteLayer extends LineOptions {
  RouteLayer({required List<LatLng> points, double lineWidth = 7.0})
      : super(
          geometry: points,
          lineWidth: lineWidth,
          lineColor: "rgb(0, 115, 255)",
          lineJoin: "round",
        );
}

/// A background line layer for the route.
class RouteBackgroundLayer extends LineOptions {
  RouteBackgroundLayer({required List<LatLng> points, double lineWidth = 9.0})
      : super(
          geometry: points,
          lineWidth: lineWidth,
          lineColor: "#C6C6C6",
          lineJoin: "round",
        );
}

/// A transparent layer that is much wider than the route.
/// This layer can be used to make tapping a route easier.
class RouteBackgroundClickLayer extends LineOptions {
  RouteBackgroundClickLayer({required List<LatLng> points})
      : super(
          geometry: points,
          lineWidth: 25.0,
          lineColor: "transparent",
          lineJoin: "round",
        );
}

/// A line layer that shows a discomfortable section.
class DiscomfortSectionLayer extends LineOptions {
  DiscomfortSectionLayer({required List<LatLng> points})
      : super(
          geometry: points,
          lineWidth: 7.0,
          lineColor: "rgb(230, 51, 40)",
          lineJoin: "round",
        );
}

/// A transparent line layer that is much wider than a discomfort
/// section layer, to make clicking on discomforts easier.
class DiscomfortSectionClickLayer extends LineOptions {
  DiscomfortSectionClickLayer({required List<LatLng> points})
      : super(
          geometry: points,
          lineWidth: 30.0,
          lineColor: "transparent",
          lineJoin: "round",
        );
}
