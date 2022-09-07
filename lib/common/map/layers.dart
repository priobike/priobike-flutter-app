import 'package:mapbox_gl/mapbox_gl.dart';

class RouteLayer extends LineOptions {
  RouteLayer({ required List<LatLng> points, double lineWidth = 7.0 }) : super(
    geometry: points,
    lineWidth: lineWidth,
    lineColor: "#0094FF",
    lineJoin: "round",
  );
}

class RouteBackgroundLayer extends LineOptions {
  RouteBackgroundLayer({ required List<LatLng> points, double lineWidth = 9.0 }) : super(
    geometry: points,
    lineWidth: lineWidth,
    lineColor: "#C6C6C6",
    lineJoin: "round",
  );
}

class RouteBackgroundClickLayer extends LineOptions {
  RouteBackgroundClickLayer({ required List<LatLng> points }) : super(
    geometry: points,
    lineWidth: 25.0,
    lineColor: "transparent",
    lineJoin: "round",
  );
}

class DiscomfortSectionLayer extends LineOptions {
  DiscomfortSectionLayer({ required List<LatLng> points }) : super(
    geometry: points,
    lineWidth: 7.0,
    lineColor: "#FF0000",
    lineJoin: "round",
  );
}

class DiscomfortSectionClickLayer extends LineOptions {
  DiscomfortSectionClickLayer({ required List<LatLng> points }) : super(
    geometry: points,
    lineWidth: 30.0,
    lineColor: "transparent",
    lineJoin: "round",
  );
}