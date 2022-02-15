import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/cycling_views/default.dart';
import 'package:priobike/cycling_views/minimal_json.dart';
import 'package:priobike/services/app.dart';
import 'package:priobike/utils/logger.dart';
import 'package:priobike/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';
import 'package:priobike/cycling_views/default_debug.dart';

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

  final PageController _pageController = PageController(
    initialPage: 0,
  );

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

    const styleTrue = TextStyle(color: Colors.green);
    const styleFalse = TextStyle(color: Colors.red);

    return SafeArea(
      child: Scaffold(
        body: app.currentRecommendation != null
            ? PageView(
                controller: _pageController,
                scrollDirection: Axis.horizontal,
                children: [
                  DefaultCyclingView(
                    app.currentRecommendation!,
                    app.lastPosition!,
                  ),
                  DefaultDebugCyclingView(
                    app.currentRecommendation!,
                    app.lastPosition!,
                  ),
                  MinimalDebugCyclingView(
                    app.currentRecommendation!,
                  ),
                ],
              )
            : Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    app.currentRoute != null
                        ? const Text(
                            "✓ Route vorhanden",
                            style: styleTrue,
                          )
                        : const Text(
                            "✕ Route nicht berechnet",
                            style: styleFalse,
                          ),
                    app.lastPosition != null
                        ? const Text(
                            "✓ Position vorhanden",
                            style: styleTrue,
                          )
                        : const Text(
                            "✕ Warte auf GPS Position...",
                            style: styleFalse,
                          ),
                    const Text(
                      "✕ Warte auf erste Empfehlung vom Server...",
                      style: styleFalse,
                    ),
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
