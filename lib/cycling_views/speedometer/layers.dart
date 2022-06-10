import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// A map layer which marks the route on the map.
class RouteLayer extends PolylineLayerOptions {
  RouteLayer({ required List<LatLng> points }) : super(
    polylines: [
      Polyline(
        points: points,
        strokeWidth: 8.0,
        color: const Color.fromARGB(255, 52, 152, 219),
      ),
    ],
  );
}

/// A map layer which shows the "Positron" Carto map
class PositronMapLayer extends TileLayerOptions {
  PositronMapLayer() : super(
    // NOTE: In the future, we will use mapbox tiles
    urlTemplate: "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
    subdomains: ['a', 'b', 'c'],
  );
}