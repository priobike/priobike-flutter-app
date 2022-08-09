import 'package:mapbox_gl/mapbox_gl.dart';

class RouteLayer extends LineOptions {
  RouteLayer({ required List<LatLng> points }) : super(
    geometry: points,
    lineWidth: 7.0,
    lineColor: "#0094FF",
    lineJoin: "round",
  );
}

class RouteBackgroundLayer extends LineOptions {
  RouteBackgroundLayer({ required List<LatLng> points }) : super(
    geometry: points,
    lineWidth: 10.0,
    lineColor: "#4b6584",
    lineJoin: "round",
  );
}

class AltRouteLayer extends LineOptions {
  AltRouteLayer({ required List<LatLng> points }) : super(
    geometry: points,
    lineWidth: 7.0,
    lineColor: "#d1d8e0",
    lineJoin: "round",
  );
}

class AltRouteBackgroundLayer extends LineOptions {
  AltRouteBackgroundLayer({ required List<LatLng> points }) : super(
    geometry: points,
    lineWidth: 9.0,
    lineColor: "#4b6584",
    lineJoin: "round",
    lineBlur: 0,
  );
}

class AltRouteClickLayer extends LineOptions {
  AltRouteClickLayer({ required List<LatLng> points }) : super(
    geometry: points,
    lineWidth: 100.0,
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