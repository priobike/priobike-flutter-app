

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/routing/messages/graphhopper/response.dart';
import 'package:priobike/routing/models/discomfort.dart';
import 'package:provider/provider.dart';

class DiscomfortFinder {
  /// The calculated GraphHopper path.
  final GHRouteResponsePath path;

  const DiscomfortFinder({required this.path});

  /// Get the coordinates for a given segment.
  List<LatLng> getCoordinates(GHSegment segment) {
    List<LatLng> coordinates = [];
    for (int i = segment.from; i <= segment.to; i++) {
      final c = path.points.coordinates[i];
      coordinates.add(LatLng(c.lat, c.lon));
    }
    return coordinates;
  }

  Future<List<Discomfort>> findDiscomforts(BuildContext context) async {
    final profile = Provider.of<ProfileService>(context, listen: false);
    
    // Use the smoothness values to determine unsmooth sections.
    // See: https://wiki.openstreetmap.org/wiki/DE:Key:smoothness
    final unsmooth = path.details.smoothness
      .map((segment) {
        if (segment.value == null) return null;
        final cs = getCoordinates(segment);
        if (segment.value == "impassable") {
          return Discomfort(coordinates: cs, description: "Nicht passierbarer Wegabschnitt.");
        } else if (segment.value == "very_horrible") {
          return Discomfort(coordinates: cs, description: "Wegabschnitt mit tiefen Spurrillen oder anderen größeren Hindernissen.");
        } else if (segment.value == "horrible") {
          return Discomfort(coordinates: cs, description: "Nicht versiegelter oder unbefestigter Wegabschnitt mit Spurrillen, Felsen oder anderen Hindernissen.");
        } else if (segment.value == "very_bad") {
          return Discomfort(coordinates: cs, description: "Nicht versiegelter oder unbefestigter Wegabschnitt mit Schlaglöchern, Spurrillen oder anderen Hindernissen.");
        } else if (segment.value == "bad") {
          return Discomfort(coordinates: cs, description: "Wegabschnitt mit stark beschädigter Oberfläche.");
        } else if (segment.value == "intermediate" && profile.bikeType == BikeType.racingbike) {
          return Discomfort(coordinates: cs, description: "Asphaltierter Wegabschnitt mit Beschädigungen, die für Rennräder ungeeignet sind.");
        }
      })
      .where((e) => e != null)
      .map((e) => e!)
      .toList();
    
    return unsmooth;
  }
}