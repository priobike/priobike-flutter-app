import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:priobike/services/app.dart';
import 'package:priobike/utils/routes.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../v2/common/logger.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _RoutePageState();
  }
}

class _RoutePageState extends State<RoutePage> {
  Logger log = Logger("RoutePage");
  late AppService app;
  var points = <LatLng>[];
  var trafficLights = <Marker>[];

  @override
  void didChangeDependencies() {
    app = Provider.of<AppService>(context);

    if (!app.isGeolocating) {
      app.startGeolocation();
    }

    if (app.currentRoute != null && !app.loadingRoute) {
      points = [];
      trafficLights = [];

      log.i("getting points and traffic lights from route");

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
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Routenübersicht'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: !app.loadingRoute
              ? Column(
                  children: [
                    SizedBox(
                      height: 300,
                      child: FlutterMap(
                        options: MapOptions(
                          bounds: LatLngBounds.fromPoints(points),
                          boundsOptions: const FitBoundsOptions(
                              padding: EdgeInsets.all(30)),
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
                            // "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
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
                              Marker(
                                point: points.first,
                                builder: (ctx) => Icon(
                                  Icons.location_pin,
                                  color: Colors.blue[900],
                                  size: 30,
                                ),
                              ),
                              Marker(
                                point: points.last,
                                builder: (ctx) => Icon(
                                  Icons.flag,
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
                    Text(
                        "Länge der Strecke: ${app.currentRoute?.distance.toStringAsFixed(0)}m"),
                    Text("Anzahl der Ampeln: ${trafficLights.length}"),
                    Text("Meter nach oben: ${app.currentRoute?.ascend}"),
                    Text("Meter nach unten: ${app.currentRoute?.descend}"),
                    app.currentRoute != null
                        ? Text(
                            "Dauer: ${(app.currentRoute!.estimatedDuration / 1000 / 60).toStringAsFixed(1)} Min.")
                        : const Text(''),
                    const Spacer(),
                    Text("SessionID: ${app.session?.sessionId}"),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Zurück'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.pedal_bike),
                        label: const Text('Jetzt losfahren'),
                        onPressed: () {
                          app.startNavigation();
                          Navigator.pushReplacementNamed(
                              context, Routes.cycling);
                        },
                      ),
                    ),
                  ],
                  crossAxisAlignment: CrossAxisAlignment.start,
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Center(
                      child: Text("Warte auf Route vom Server..."),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    log.i("RoutingPage disposed.");

    if (!app.isNavigating) {
      app.stopGeolocation();
    }

    super.dispose();
  }
}
