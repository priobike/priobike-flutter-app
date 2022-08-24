import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/ride/views/button.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

class DefaultDebugCyclingView extends StatefulWidget {
  const DefaultDebugCyclingView({Key? key}) : super(key: key);

  @override
  State<DefaultDebugCyclingView> createState() =>
      _DefaultDebugCyclingViewState();
}

class _DefaultDebugCyclingViewState extends State<DefaultDebugCyclingView> {
  late RoutingService routingService;
  late RideService rideService;
  late PositionService positionService;

  var points = <LatLng>[];
  var trafficLights = <Marker>[];
  var routeDrawn = false;

  @override
  void didChangeDependencies() {
    routingService = Provider.of<RoutingService>(context);
    rideService = Provider.of<RideService>(context);
    positionService = Provider.of<PositionService>(context);

    if (routingService.selectedRoute != null && !routeDrawn) {
      for (var point in routingService.selectedRoute!.route) {
        points.add(LatLng(point.lat, point.lon));
      }

      for (var sg in routingService.selectedRoute!.signalGroups.values) {
        trafficLights.add(
          Marker(
            point: LatLng(sg.position.lat, sg.position.lon),
            builder: (ctx) => Icon(
              Icons.traffic,
              color: Colors.red[900],
              size: 20,
            ),
          ),
        );
      }

      routeDrawn = true;
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (rideService.currentRecommendation == null) return Container();
    if (positionService.lastPosition == null) return Container();
    return Scaffold(
      backgroundColor: rideService.currentRecommendation!.isGreen
          ? const Color(0xff4caf50)
          : const Color(0xfff44235),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rideService.currentRecommendation!.label,
              style: const TextStyle(fontSize: 30),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: Container(
                alignment: Alignment.center,
                color: Colors.black54,
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Text("${rideService.currentRecommendation!.countdown}s ",
                        style: const TextStyle(fontSize: 40)),
                    const Spacer(),
                    Text(
                        "${rideService.currentRecommendation!.distance.toStringAsFixed(0)}m",
                        style: const TextStyle(fontSize: 40)),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 250,
              child: FlutterMap(
                options: MapOptions(
                  bounds: LatLngBounds.fromPoints(points),
                  boundsOptions:
                      const FitBoundsOptions(padding: EdgeInsets.all(30)),
                  zoom: 13.0,
                  maxZoom: 20.0,
                  minZoom: 7,
                  interactiveFlags: InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.flingAnimation |
                      InteractiveFlag.pinchMove,
                ),
                layers: [
                  TileLayerOptions(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                  ),
                  PolylineLayerOptions(
                    polylines: [
                      Polyline(
                        points: points,
                        strokeWidth: 4.0,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  MarkerLayerOptions(
                    markers: [
                      ...trafficLights,
                      positionService.lastPosition != null
                          ? Marker(
                              point: LatLng(positionService.lastPosition!.latitude,
                                  positionService.lastPosition!.longitude),
                              builder: (ctx) => Icon(
                                Icons.location_pin,
                                color: Colors.blue[900],
                                size: 30,
                              ),
                            )
                          : Marker(
                              point: LatLng(0, 0),
                              builder: (ctx) => Container()),
                      Marker(
                        point: points.last,
                        builder: (ctx) => Icon(
                          Icons.flag,
                          color: Colors.green[900],
                          size: 30,
                        ),
                      ),
                      Marker(
                        point: LatLng(
                          rideService.currentRecommendation!.snapPos.lat,
                          rideService.currentRecommendation!.snapPos.lon,
                        ),
                        builder: (ctx) => Icon(
                          Icons.my_location,
                          color: Colors.green[900],
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "Aktuell: ${(positionService.lastPosition!.speed * 3.6).toStringAsFixed(1)}km/h",
              style: const TextStyle(fontSize: 25),
            ),
            Text(
              "Empfohlen: ${(rideService.currentRecommendation!.speedRec * 3.6).toStringAsFixed(1)}km/h",
              style: const TextStyle(fontSize: 25),
            ),
            const Spacer(),
            Text(
              "${(rideService.currentRecommendation!.speedDiff * 3.6).toStringAsFixed(1)}km/h",
              style: const TextStyle(fontSize: 35),
            ),
            if (rideService.currentRecommendation!.speedDiff > 0)
              const Text("Schneller!", style: TextStyle(fontSize: 25)),
            if (rideService.currentRecommendation!.speedDiff < 0)
              const Text("Langsamer!", style: TextStyle(fontSize: 25)),
            if (rideService.currentRecommendation!.speedDiff == 0)
              const Text("Geschwindigkeit halten.",
                  style: TextStyle(fontSize: 25)),
            const Spacer(),
            Text(
              rideService.currentRecommendation!.error
                  ? "Fehler: ${rideService.currentRecommendation!.errorMessage}"
                  : '',
              style: const TextStyle(fontSize: 20, color: Colors.yellow),
            ),
            const SizedBox(
              width: double.infinity,
              child: CancelButton(),
            ),
          ],
        ),
      ),
    );
  }
}
