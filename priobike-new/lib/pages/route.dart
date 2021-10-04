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

  @override
  void didChangeDependencies() {
    app = Provider.of<AppService>(context);

    if (!app.isGeolocating) {
      app.startGeolocation();
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    var points = <LatLng>[
      LatLng(53.57191899068744, 9.97833251953125),
      LatLng(53.56937054368435, 9.980220794677734),
      LatLng(53.56468099991129, 9.982280731201172),
      LatLng(53.562539948350995, 9.988975524902344),
      LatLng(53.561010559454914, 9.989490509033201),
      LatLng(53.55968504435065, 9.990863800048828),
      LatLng(53.55866538908501, 9.997901916503906),
      LatLng(53.557849647177584, 9.998760223388672),
      LatLng(53.55723783042491, 10.006656646728516),
      LatLng(53.556014170376706, 10.010604858398438),
      LatLng(53.55489245090933, 10.011634826660156),
      LatLng(53.5524449597555, 10.012664794921875),
      LatLng(53.54999732703289, 10.0140380859375),
      LatLng(53.54826350153167, 10.01455307006836),
    ];

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PrioBike: RoutePage'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              SizedBox(
                height: 400,
                child: FlutterMap(
                  options: MapOptions(
                    center: LatLng(53.551086, 9.993682),
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
                        Marker(
                          width: 80.0,
                          height: 80.0,
                          point: LatLng(53.557849647177584, 9.998760223388672),
                          builder: (ctx) => const FlutterLogo(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
          ),
        ),
      ),
    );
  }
}
