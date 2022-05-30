import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:priobike/models/recommendation.dart';
import 'package:priobike/widgets/navigation_arrow.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/services/app.dart';

import 'package:priobike/utils/routes.dart';

class MinimalNavigationCyclingView extends StatefulWidget {
  const MinimalNavigationCyclingView({Key? key}) : super(key: key);

  @override
  State<MinimalNavigationCyclingView> createState() =>
      _MinimalNavigationCyclingViewState();
}

class _MinimalNavigationCyclingViewState
    extends State<MinimalNavigationCyclingView> {
  late AppService app;

  var points = <LatLng>[];
  var trafficLights = <Marker>[];
  var routeDrawn = false;

  @override
  void didChangeDependencies() {
    app = Provider.of<AppService>(context);

    if (app.currentRoute != null && !routeDrawn) {
      for (var point in app.currentRoute!.route) {
        points.add(LatLng(point.lat, point.lon));
      }

      for (var sg in app.currentRoute!.signalgroups.values) {
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
    Recommendation recommendation = app.currentRecommendation!;

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
                    child: AutoSizeText(
                      recommendation.navText,
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
                    attributionBuilder: (_) {
                      return const Text(
                        "© OpenStreetMap Mitwirkende",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 10,
                        ),
                      );
                    },
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
                      app.lastPosition != null
                          ? Marker(
                              point: LatLng(app.lastPosition!.latitude,
                                  app.lastPosition!.longitude),
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
                          app.currentRecommendation!.snapPos.lat,
                          app.currentRecommendation!.snapPos.lon,
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.stop),
                label: const Text('Fahrt beenden'),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, Routes.summary);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
