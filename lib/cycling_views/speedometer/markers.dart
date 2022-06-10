import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// A map layer which marks a traffic light on the map.
class TrafficLightMarker extends Marker {
  TrafficLightMarker({
    required double lat,
    required double lon,
  }): super(
    point: LatLng(lat, lon),
    builder: (context) => Container(
      child: const Icon(
        Icons.traffic,
        color: Color.fromARGB(255, 236, 240, 241),
        size: 30,
      ),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 44, 62, 80).withOpacity(1.0),
            spreadRadius: 2,
            blurRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
    ),
  );
}

/// A map layer which marks the current position on the map.
class CurrentPositionMarker extends Marker {
  CurrentPositionMarker({
    double? lat,
    double? lon,
  }): super(
    point: lat != null && lon != null ? LatLng(lat, lon) : LatLng(0, 0),
    builder: lat != null && lon != null ? (ctx) => Container(
      child: const Icon(
        Icons.location_pin,
        color: Color.fromARGB(255, 236, 240, 241),
        size: 30,
      ),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 231, 76, 60).withOpacity(1.0),
            spreadRadius: 2,
            blurRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
    ) : (ctx) => Container(),
  );
}

/// A map layer which marks the start position on the map.
class StartMarker extends Marker {
  StartMarker({
    required double lat,
    required double lon,
  }): super(
    point: LatLng(lat, lon),
    builder: (ctx) => const Icon(
      Icons.location_pin,
      color: Color.fromARGB(255, 44, 62, 80),
      size: 30,
    ),
  );
}

/// A map layer which marks the end position on the map.
class DestinationMarker extends Marker {
  DestinationMarker({
    required double lat,
    required double lon,
  }): super(
    point: LatLng(lat, lon),
    builder: (ctx) => const Icon(
      Icons.flag,
      color: Color.fromARGB(255, 44, 62, 80),
      size: 30,
    ),
  );
}
