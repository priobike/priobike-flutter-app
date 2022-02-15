import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:priobike/models/recommendation.dart';

import '../utils/routes.dart';

class DefaultDebugCyclingView extends StatelessWidget {
  DefaultDebugCyclingView(
    this.recommendation,
    this.lastPosition,
  );

  final Recommendation recommendation;
  final Position lastPosition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: recommendation.green
          ? const Color(0xff4caf50)
          : const Color(0xfff44235),
      body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recommendation.label,
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
                      Text("${recommendation.countdown}s ",
                          style: const TextStyle(fontSize: 40)),
                      const Spacer(),
                      Text("${recommendation.distance.toStringAsFixed(0)}m",
                          style: const TextStyle(fontSize: 40)),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ),
              // SizedBox(
              //   height: 250,
              //   child: FlutterMap(
              //     options: MapOptions(
              //       bounds: LatLngBounds.fromPoints(points),
              //       boundsOptions: const FitBoundsOptions(
              //           padding: EdgeInsets.all(30)),
              //       zoom: 13.0,
              //       maxZoom: 20.0,
              //       minZoom: 7,
              //       interactiveFlags: InteractiveFlag.drag |
              //           InteractiveFlag.pinchZoom |
              //           InteractiveFlag.doubleTapZoom |
              //           InteractiveFlag.flingAnimation |
              //           InteractiveFlag.pinchMove,
              //     ),
              //     layers: [
              //       TileLayerOptions(
              //         urlTemplate:
              //             "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              //         subdomains: ['a', 'b', 'c'],
              //         attributionBuilder: (_) {
              //           return const Text(
              //             "© OpenStreetMap Mitwirkende",
              //             style: TextStyle(
              //               color: Colors.black54,
              //               fontSize: 10,
              //             ),
              //           );
              //         },
              //       ),
              //       PolylineLayerOptions(
              //         polylines: [
              //           Polyline(
              //             points: points,
              //             strokeWidth: 4.0,
              //             color: Colors.blue,
              //           ),
              //         ],
              //       ),
              //       MarkerLayerOptions(
              //         markers: [
              //           ...trafficLights,
              //           app.lastPosition != null
              //               ? Marker(
              //                   point: LatLng(
              //                       app.lastPosition!.latitude,
              //                       app.lastPosition!.longitude),
              //                   builder: (ctx) => Icon(
              //                     Icons.location_pin,
              //                     color: Colors.blue[900],
              //                     size: 30,
              //                   ),
              //                 )
              //               : Marker(
              //                   point: LatLng(0, 0),
              //                   builder: (ctx) => Container()),
              //           Marker(
              //             point: points.last,
              //             builder: (ctx) => Icon(
              //               Icons.flag,
              //               color: Colors.green[900],
              //               size: 30,
              //             ),
              //           ),
              //           Marker(
              //             point: LatLng(
              //               recommendation!.snapPos.lat,
              //               recommendation!.snapPos.lon,
              //             ),
              //             builder: (ctx) => Icon(
              //               Icons.my_location,
              //               color: Colors.green[900],
              //               size: 30,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 15),
              Text(
                "Aktuell: ${(lastPosition.speed * 3.6).toStringAsFixed(1)}km/h",
                style: const TextStyle(fontSize: 25),
              ),
              Text(
                "Empfohlen: ${(recommendation.speedRec * 3.6).toStringAsFixed(1)}km/h",
                style: const TextStyle(fontSize: 25),
              ),
              const Spacer(),
              Text(
                "${(recommendation.speedDiff * 3.6).toStringAsFixed(1)}km/h",
                style: const TextStyle(fontSize: 35),
              ),
              if (recommendation.speedDiff > 0)
                const Text("Schneller!", style: TextStyle(fontSize: 25)),
              if (recommendation.speedDiff < 0)
                const Text("Langsamer!", style: TextStyle(fontSize: 25)),
              if (recommendation.speedDiff == 0)
                const Text("Geschwindigkeit halten.",
                    style: TextStyle(fontSize: 25)),
              const Spacer(),
              Text(
                recommendation.error
                    ? "Fehler: ${recommendation.errorMessage}"
                    : '',
                style: const TextStyle(fontSize: 20, color: Colors.yellow),
              ),
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
          )),
    );
  }
}
