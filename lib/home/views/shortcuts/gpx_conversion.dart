import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/map/map_projection.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:proj4dart/src/classes/point.dart';

double calcAngle(x1, y1, x2, y2) {
  double xDiff = x2 - x1;
  double yDiff = y2 - y1;
  double abs = sqrt(pow(xDiff, 2) + pow(yDiff, 2));
  if (abs == 0) return 0;
  return acos(xDiff / abs);
}

double calcDistance(x1, y1, x2, y2) {
  return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
}

List initialApproximation(List<double> xsGpx, List<double> ysGpx) {
  double angleThresh = (1 / 10) * pi;
  double d1Thresh = 10000.0;
  double d2Thresh = 5000.0;

  double xLast = xsGpx.first;
  double yLast = ysGpx.first;
  double angleLast = 0;
  List<double> xsApprox = [xLast];
  List<double> ysApprox = [yLast];
  List<int> indicesGpx = [0];
  for (int i = 0; i < xsGpx.length; i++) {
    double x = xsGpx[i];
    double y = ysGpx[i];
    double angle = calcAngle(x, y, xLast, yLast);
    double distance = calcDistance(x, y, xLast, yLast);
    if (distance > d1Thresh || ((angleLast - angle).abs() > angleThresh && distance > d2Thresh)) {
      xsApprox.add(x);
      ysApprox.add(y);
      indicesGpx.add(i);
      xLast = x;
      yLast = y;
      angleLast = angle;
    }
  }
  xsApprox.add(xsGpx.last);
  ysApprox.add(ysGpx.last);
  indicesGpx.add(xsGpx.length - 1);
  return [xsApprox, ysApprox, indicesGpx];
}

Future<List> reconstructRoute(List<double> approxXs, List<double> approxYs, Routing routing) async {
  double x, y;
  List<double> approxLngs = [];
  List<double> approxLats = [];
  for (int i = 0; i < approxXs.length; i++) {
    x = approxXs[i];
    y = approxYs[i];
    LatLng latLng = MapboxMapProjection.convertMercatorToLatLon(x, y);
    approxLats.add(latLng.latitude);
    approxLngs.add(latLng.longitude);
  }
  int maxWaypoints = 200; // max number of waypoints for gh is 238
  List<Waypoint> waypoints = [];
  for (int i = 0; i < approxLngs.length; i++) {
    waypoints.add(Waypoint(approxLats[i], approxLngs[i]));
  }
  GHRouteResponse? response = await routing.loadGHRouteResponse(waypoints);
  if (response == null) throw Exception();
  List<GHCoordinate> coordinates = response.paths[0].points.coordinates;
  List<double> recXs = [];
  List<double> recYs = [];
  for (GHCoordinate coordinate in coordinates) {
    Point point = MapboxMapProjection.convertLatLonToMercator(coordinate.lat, coordinate.lon);
    recXs.add(point.x);
    recYs.add(point.y);
  }
  return [recXs, recYs];
}

List cost(List<double> gpxXs, List<double> gpxYs, List<double> recXs, List<double> recYs) {
  // calc distance of original gpx to reconstructed route
  // for each point of gpx route calc distance to the closest point of reconstructed route
  final ds = <double>[];
  double totalD = 0;

  if (gpxXs.isEmpty) {
    return [ds, totalD];
  }

  for (var j = 0; j < gpxXs.length; j++) {
    final gpxX = gpxXs[j];
    final gpxY = gpxYs[j];
    double d = double.infinity;

    for (var i = 0; i < recXs.length; i++) {
      final recX = recXs[i];
      final recY = recYs[i];
      final localD = sqrt(pow(recX - gpxX, 2) + pow(recY - gpxY, 2));
      if (localD < d) d = localD;
    }
    ds.add(d);
    totalD += d;
  }
  final averageD = totalD / gpxXs.length;
  return [ds, averageD];
}

Future<List> iterativelyImproveApprox(List<double> gpxXs, List<double> gpxYs, Routing routing, ValueSetter<List<Wpt>> callback) async {
  List<double> approxXs, approxYs;
  List<int> gpxIndices;

  List initApprox = initialApproximation(gpxXs, gpxYs);
  approxXs = initApprox[0];
  approxYs = initApprox[1];
  gpxIndices = initApprox[2];

  List<double> recXs, recYs;
  List reconstruction = await reconstructRoute(approxXs, approxYs, routing);
  recXs = reconstruction[0];
  recYs = reconstruction[1];
  emitProgress(recXs, recYs, callback);

  List<double> cs;
  double lastCost, totalCost;
  lastCost = double.infinity;
  List costVal = cost(gpxXs, gpxYs, recXs, recYs);
  cs = costVal[0];
  totalCost = costVal[1];
  double dThreshGlobal = 100;
  double dThreshLocal = 200;
  while (totalCost > dThreshGlobal && dThreshLocal > 100) {
    List insertions = [];
    for (int i = 0; i < approxXs.length - 1; i++) {
      reconstruction = await reconstructRoute(approxXs.sublist(i, i + 2), approxYs.sublist(i, i + 2), routing);
      recXs = reconstruction[0];
      recYs = reconstruction[1];
      costVal = cost(gpxXs.sublist(gpxIndices[i], gpxIndices[i + 1] - 1),
          gpxYs.sublist(gpxIndices[i], gpxIndices[i + 1] - 1), recXs, recYs);
      cs = costVal[0];
      totalCost = costVal[1];
      if (cs.isEmpty) continue;
      int iMax = gpxIndices[i] + argMax(cs);
      if (totalCost > dThreshLocal) insertions.insert(0, [i + 1, iMax, gpxXs[iMax], gpxYs[iMax]]);
    }
    for (List insertion in insertions) {
      gpxIndices.insert(insertion[0], insertion[1]);
      approxXs.insert(insertion[0], insertion[2]);
      approxYs.insert(insertion[0], insertion[3]);
    }
    reconstruction = await reconstructRoute(approxXs, approxYs, routing);
    recXs = reconstruction[0];
    recYs = reconstruction[1];
    costVal = cost(gpxXs, gpxYs, recXs, recYs);
    if (totalCost == lastCost) dThreshLocal = dThreshLocal / 2;
    lastCost = totalCost;

    emitProgress(recXs, recYs, callback);
  }
  return [approxXs, approxYs];
}

void emitProgress(List<double> xs, List<double> ys, ValueSetter<List<Wpt>> callback){
  List<Wpt> wpts = [];
  for(int j = 0; j < xs.length; j++){
    LatLng latLng = MapboxMapProjection.convertMercatorToLatLon(xs[j], ys[j]);
    wpts.add(Wpt(lat: latLng.latitude, lon: latLng.longitude));
  }
  callback.call(wpts);
}

int argMax(List<double> list) {
  if (list.isEmpty) throw Exception('can\'t calculate arg max of empty list');
  int maxI = 0;
  double max = 0;
  for (int i = 0; i < list.length; i++) {
    double el = list[i];
    if (el > max) {
      max = el;
      maxI = i;
    }
  }
  return maxI;
}

Future<List<Waypoint>> reduceWpts(List<Wpt> wpts, Routing routing, ValueSetter<List<Wpt>> callback) async {
  // check if all waypoints are within Hamburg
  List<Waypoint> initWaypoints = [];
  for (int i = 0; i < wpts.length; i++) {
    initWaypoints.add(Waypoint(wpts[i].lat!, wpts[i].lon!));
  }
  if (!routing.inCityBoundary(initWaypoints)){
    ToastMessage.showError('Ein oder mehrere Punkte der GPX Datei liegen nicht in Hamburg.');
  }
  List<double> gpxXs = [];
  List<double> gpxYs = [];
  for (Wpt wpt in wpts) {
    double? lat = wpt.lat;
    double? lon = wpt.lon;
    if (lat != null && lon != null) {
      Point point = MapboxMapProjection.convertLatLonToMercator(lat, lon);
      gpxXs.add(point.x);
      gpxYs.add(point.y);
    }
  }
  List<double> approxXs = [];
  List<double> approxYs = [];
  List approx = await iterativelyImproveApprox(gpxXs, gpxYs, routing, callback);
  approxXs = approx[0];
  approxYs = approx[1];
  List<Waypoint> waypoints = [];
  for (int i = 0; i < approxXs.length; i++) {
    LatLng latLng = MapboxMapProjection.convertMercatorToLatLon(approxXs[i], approxYs[i]);
    waypoints.add(Waypoint(latLng.latitude, latLng.longitude, address: 'Wegpunkt $i'));
  }
  return waypoints;
}
