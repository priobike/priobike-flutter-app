import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/ride/views/button.dart';
import 'package:priobike/ride/views/legacy/arrow.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

class MinimalNavigationCyclingView extends StatefulWidget {
  const MinimalNavigationCyclingView({Key? key}) : super(key: key);

  @override
  State<MinimalNavigationCyclingView> createState() =>
      _MinimalNavigationCyclingViewState();
}

class _MinimalNavigationCyclingViewState
    extends State<MinimalNavigationCyclingView> {
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
    final recommendation = rideService.currentRecommendation!;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 8.0, 8.0, 8.0),
                child: NavigationArrow(
                  sign: recommendation.navSign,
                  width: 70,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  recommendation.navDist != 0
                      ? Text(
                          "${recommendation.navDist.toStringAsFixed(0)} m",
                          style: const TextStyle(
                            fontSize: 40,
                          ),
                        )
                      : const Text(''),
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 130,
                    child: Text(
                      recommendation.navText ?? "",
                      style: const TextStyle(fontSize: 25),
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ]),
            const Spacer(),
            SizedBox(
              height: MediaQuery.of(context).size.height - 400,
              // TODO: Replace FlutterMap with MapboxGL in the future
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
            const Spacer(),
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
