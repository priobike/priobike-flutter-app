import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:priobike/services/app.dart';
import 'package:priobike/utils/routes.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _RoutePageState();
  }
}

class _RoutePageState extends State<RoutePage> {
  late AppService app;
  var points = <LatLng>[];
  var trafficLights = <Marker>[];

  @override
  void didChangeDependencies() {
    app = Provider.of<AppService>(context);

    if (!app.isGeolocating) {
      app.startGeolocation();
    }

    app.currentRoute?.route?.forEach(
      (point) => points.add(LatLng(point.lat!, point.lon!)),
    );

    app.currentRoute?.signalgroups?.forEach(
      (sg) => trafficLights.add(
        Marker(
          point: LatLng(sg.lat!, sg.lon!),
          builder: (ctx) => Icon(
            Icons.traffic,
            color: Colors.red[900],
            size: 20,
          ),
        ),
      ),
    );

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PrioBike: RoutePage'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: app.currentRoute != null && points.isNotEmpty
              ? Column(
                  children: [
                    SizedBox(
                      height: 400,
                      child: FlutterMap(
                        options: MapOptions(
                          bounds: LatLngBounds.fromPoints(points),
                          boundsOptions: const FitBoundsOptions(
                              padding: EdgeInsets.all(30)),
                          zoom: 13.0,
                          maxZoom: 18.0,
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
                    Text("Länge der Strecke: ${app.currentRoute?.distance}m"),
                    Text("Anzahl der Ampeln: ${trafficLights.length}"),
                    Text("Meter nach oben: ${app.currentRoute?.ascend}"),
                    Text("Meter nach unten: ${app.currentRoute?.descend}"),
                    Text("Dauer in Sekunden: ${app.currentRoute?.time}"),
                    ElevatedButton(
                      child: const Text('Zur Fahransicht'),
                      onPressed: () {
                        app.startNavigation();
                        Navigator.pushReplacementNamed(context, Routes.cycling);
                      },
                    ),
                    ElevatedButton(
                      child: const Text('Zurück'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                  crossAxisAlignment: CrossAxisAlignment.start,
                )
              : const Text("Warte auf Route vom Server"),
        ),
      ),
    );
  }
}
