import 'package:mapbox_gl/mapbox_gl.dart';

class RouteLayer extends LineOptions {
  RouteLayer({ required List<LatLng> points }) : super(
    geometry: points,
    lineWidth: 7.0,
    lineColor: "#0094FF",
    lineJoin: "round",
  );
}

class AltRouteLayer extends LineOptions {
  AltRouteLayer({ required List<LatLng> points }) : super(
    geometry: points,
    lineWidth: 7.0,
    lineColor: "#C6C6C6",
    lineJoin: "round",
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