import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/services/app.dart';
import 'package:priobike/utils/logger.dart';
import 'package:priobike/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

class CyclingPage extends StatefulWidget {
  const CyclingPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CyclingPageState();
  }
}

class _CyclingPageState extends State<CyclingPage> {
  Logger log = Logger("CyclingPage");
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
    Wakelock.enable();
    return SafeArea(
      child: Scaffold(
        backgroundColor: app.currentRecommendation != null
            ? app.currentRecommendation!.green
                ? const Color(0xff4caf50)
                : const Color(0xfff44235)
            : const Color(0xff2e2e2e),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: app.currentRecommendation != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${app.currentRecommendation?.label}",
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
                            Text("${app.currentRecommendation?.countdown}s ",
                                style: const TextStyle(fontSize: 40)),
                            const Spacer(),
                            Text(
                                "${app.currentRecommendation?.distance.toStringAsFixed(0)}m",
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
                    const SizedBox(height: 15),
                    Text(
                      "Aktuell: ${(app.lastPosition!.speed * 3.6).toStringAsFixed(1)}km/h",
                      style: const TextStyle(fontSize: 25),
                    ),
                    Text(
                      "Empfohlen: ${(app.currentRecommendation!.speedRec * 3.6).toStringAsFixed(1)}km/h",
                      style: const TextStyle(fontSize: 25),
                    ),
                    const Spacer(),
                    Text(
                      "${(app.currentRecommendation!.speedDiff * 3.6).toStringAsFixed(1)}km/h",
                      style: const TextStyle(fontSize: 35),
                    ),
                    if (app.currentRecommendation!.speedDiff > 0)
                      const Text("Schneller!", style: TextStyle(fontSize: 25)),
                    if (app.currentRecommendation!.speedDiff < 0)
                      const Text("Langsamer!", style: TextStyle(fontSize: 25)),
                    if (app.currentRecommendation!.speedDiff == 0)
                      const Text("Geschwindigkeit halten.",
                          style: TextStyle(fontSize: 25)),
                    const Spacer(),
                    Text(
                      app.currentRecommendation!.error
                          ? "Fehler: ${app.currentRecommendation?.errorMessage}"
                          : '',
                      style:
                          const TextStyle(fontSize: 20, color: Colors.yellow),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.stop),
                        label: const Text('Fahrt beenden'),
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, Routes.summary);
                        },
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Center(child: Text("Warte auf Empfehlung vom Server...")),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    log.i("CyclingPage disposed.");

    app.stopNavigation();
    app.stopGeolocation();

    Wakelock.disable();
    super.dispose();
  }
}
