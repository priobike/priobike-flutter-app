
import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../routing/messages/graphhopper.dart';
const vincenty = Distance(roundResult: false);

/// All credits goes to graphhopper:
/// https://github.com/graphhopper/graphhopper/blob/master/core/src/main/java/com/graphhopper/util/Instructions.java
///
class DistanceHelper {
  /// mean radius of the earth
  final double R = 6371000; // m

  double calcNormalizedDist(double fromLat, double fromLon, double toLat, double toLon) {
    double sinDeltaLat = sin(degreesToRadians(toLat - fromLat) / 2);
    double sinDeltaLon = sin(degreesToRadians(toLon - fromLon) / 2);
    return sinDeltaLat * sinDeltaLat
        + sinDeltaLon * sinDeltaLon * cos(degreesToRadians(fromLat)) * cos(degreesToRadians(toLat));
  }

  double calcShrinkFactor(double aLatDeg, double bLatDeg) {
    return cos(degreesToRadians((aLatDeg + bLatDeg) / 2));
  }

  double calcNormalizedEdgeDistance(double rLatDeg, double rLonDeg,
      double aLatDeg, double aLonDeg,
      double bLatDeg, double bLonDeg) {
    double shrinkFactor = calcShrinkFactor(aLatDeg, bLatDeg);

    double aLat = aLatDeg;
    double aLon = aLonDeg * shrinkFactor;

    double bLat = bLatDeg;
    double bLon = bLonDeg * shrinkFactor;

    double rLat = rLatDeg;
    double rLon = rLonDeg * shrinkFactor;

    double deltaLon = bLon - aLon;
    double deltaLat = bLat - aLat;

    if (deltaLat == 0) {
      // special case: horizontal edge
      return calcNormalizedDist(aLatDeg, rLonDeg, rLatDeg, rLonDeg);
    }

    if (deltaLon == 0) {
      // special case: vertical edge
      return calcNormalizedDist(rLatDeg, aLonDeg, rLatDeg, rLonDeg);
    }

    double norm = deltaLon * deltaLon + deltaLat * deltaLat;
    double factor = ((rLon - aLon) * deltaLon + (rLat - aLat) * deltaLat) / norm;

    // x,y is projection of r onto segment a-b
    double cLon = aLon + factor * deltaLon;
    double cLat = aLat + factor * deltaLat;
    return calcNormalizedDist(cLat, cLon / shrinkFactor, rLatDeg, rLonDeg);
  }

  bool validEdgeDistance(double rLatDeg, double rLonDeg,
      double aLatDeg, double aLonDeg,
      double bLatDeg, double bLonDeg) {
    double shrinkFactor = calcShrinkFactor(aLatDeg, bLatDeg);
    double aLat = aLatDeg;
    double aLon = aLonDeg * shrinkFactor;

    double bLat = bLatDeg;
    double bLon = bLonDeg * shrinkFactor;

    double rLat = rLatDeg;
    double rLon = rLonDeg * shrinkFactor;

    double arX = rLon - aLon;
    double arY = rLat - aLat;
    double abX = bLon - aLon;
    double abY = bLat - aLat;
    double abAr = arX * abX + arY * abY;

    double rbX = bLon - rLon;
    double rbY = bLat - rLat;
    double abRb = rbX * abX + rbY * abY;

    // calculate the exact degree alpha(ar, ab) and beta(rb,ab) if it is case 1 then both angles are <= 90°
    // double ab_ar_norm = Math.sqrt(ar_x * ar_x + ar_y * ar_y) * Math.sqrt(ab_x * ab_x + ab_y * ab_y);
    // double ab_rb_norm = Math.sqrt(rb_x * rb_x + rb_y * rb_y) * Math.sqrt(ab_x * ab_x + ab_y * ab_y);
    // return Math.acos(ab_ar / ab_ar_norm) <= Math.PI / 2 && Math.acos(ab_rb / ab_rb_norm) <= Math.PI / 2;
    return abAr > 0 && abRb > 0;
  }

  double calcDenormalizedDist(double normedDist) {
    return R * 2 * asin(sqrt(normedDist));
  }

  /// This method is useful for navigation devices to find the next instruction for the specified
  /// coordinate (e.g. the current position).
  /// <p>
  ///
  /// @param instructions the instructions to query
  /// @param maxDistance the maximum acceptable distance to the instruction (in meter)
  /// @return the next Instruction or null if too far away.
  GHInstruction? find(GHRouteResponsePath path, List<GHInstruction> instructions, LatLng currentPosition, double maxDistance) {
    // handle special cases
    if (instructions.isEmpty) {
      return null;
    }
    List<GHCoordinate> points = getPointsOfInstruction(path, instructions[0]);
    var prevCoordinate = LatLng(points[0].lat, points[0].lon);
    // DistanceCalc distCalc = DistanceCalcEarth.DIST_EARTH;
    DistanceHelper distCalc = DistanceHelper();
    double foundMinDistance = vincenty.distance(currentPosition, prevCoordinate);
    int foundInstruction = 0;

    // Search the closest edge to the query point
    if (instructions.length > 1) {
      for (int instructionIndex = 0; instructionIndex < instructions.length; instructionIndex++) {
        points = getPointsOfInstruction(path, instructions[instructionIndex]);
        for (int pointIndex = 0; pointIndex < points.length; pointIndex++) {
          var currCoordinate = LatLng(points[pointIndex].lat, points[pointIndex].lon);

          if (!(instructionIndex == 0 && pointIndex == 0)) {
            // calculate the distance from the point to the edge
            double distance;
            int index = instructionIndex;
            if (distCalc.validEdgeDistance(currentPosition.latitude, currentPosition.longitude, currCoordinate.latitude, currCoordinate.longitude, prevCoordinate.latitude, prevCoordinate.longitude)) {
              distance = distCalc.calcNormalizedEdgeDistance(currentPosition.latitude, currentPosition.longitude, currCoordinate.latitude, currCoordinate.longitude, prevCoordinate.latitude, prevCoordinate.longitude);
              if (pointIndex > 0) {
                index++;
              }
            } else {
              distance = distCalc.calcNormalizedDist(currentPosition.latitude, currentPosition.longitude, currCoordinate.latitude, currCoordinate.longitude);
              if (pointIndex > 0) {
                index++;
              }
            }

            if (distance < foundMinDistance) {
              foundMinDistance = distance;
              foundInstruction = index;
            }
          }
          prevCoordinate = currCoordinate;
        }
      }
    }

    if (distCalc.calcDenormalizedDist(foundMinDistance) > maxDistance) {
      return null;
    }

    // special case finish condition
    if (foundInstruction == instructions.length) {
      foundInstruction--;
    }

    return instructions[foundInstruction];
  }

  List<GHCoordinate> getPointsOfInstruction(GHRouteResponsePath path, GHInstruction instruction) {
    return path.points.coordinates.sublist(instruction.interval[0], instruction.interval[1]);
  }

  GHInstruction? getNextInstruction(List<GHInstruction> preprocessedInstructions, GHInstruction currentInstruction) {
    final index = preprocessedInstructions.indexOf(currentInstruction);
    if(index + 1 <= preprocessedInstructions.length) {
      return preprocessedInstructions.elementAt(index + 1);
    }
    return null;
  }

}