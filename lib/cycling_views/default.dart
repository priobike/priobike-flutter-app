import 'package:flutter/material.dart';
import 'package:priobike/models/recommendation.dart';
import 'package:priobike/services/app.dart';
import 'package:provider/provider.dart';

import '../utils/routes.dart';

class DefaultCyclingView extends StatefulWidget {
  const DefaultCyclingView({Key? key}) : super(key: key);

  static double interpolate(double min, double max, double t) {
    final double lerp = (t - min) / (max - min);
    return lerp;
  }

  @override
  State<DefaultCyclingView> createState() => _DefaultCyclingViewState();
}

class _DefaultCyclingViewState extends State<DefaultCyclingView> {
  late AppService app;

  final double padding = 24.0;
  final int sliderThumbWidth = 20;
  final double maxSpeedDiff = 10.0;

  @override
  void didChangeDependencies() {
    app = Provider.of<AppService>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    Recommendation recommendation = app.currentRecommendation!;

    num percent = DefaultCyclingView.interpolate(
      -maxSpeedDiff,
      maxSpeedDiff,
      recommendation.speedDiff.clamp(-maxSpeedDiff, maxSpeedDiff),
    );

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              recommendation.error
                  ? "Fehler: ${recommendation.errorMessage}"
                  : '',
              style: const TextStyle(color: Colors.yellow),
            ),
            Text(recommendation.label),
            Text("${recommendation.distance.toStringAsFixed(0)}m"),
            const Spacer(),
            Stack(children: [
              SizedBox(
                height: MediaQuery.of(context).size.width / 2,
                width: MediaQuery.of(context).size.width / 2,
                child: CircularProgressIndicator(
                  strokeWidth: 30,
                  color: recommendation.green ? Colors.green : Colors.red,
                  value: recommendation.countdown / 60,
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    "${recommendation.countdown}s ",
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
              ),
            ]),
            const Spacer(),
            Stack(
              children: [
                Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.red,
                        Colors.transparent,
                        Colors.green,
                        Colors.transparent,
                        Colors.red,
                      ],
                    ),
                  ),
                ),
                Positioned.directional(
                  textDirection: TextDirection.ltr,
                  start: (MediaQuery.of(context).size.width - padding * 2) *
                          percent -
                      (sliderThumbWidth / 2),
                  child: Container(
                    height: 100,
                    width: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color.fromARGB(255, 54, 54, 54),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Text("${(recommendation.speedDiff * 3.6).toStringAsFixed(1)}km/h"),
            if (recommendation.speedDiff > 0) const Text("Schneller!"),
            if (recommendation.speedDiff < 0) const Text("Langsamer!"),
            if (recommendation.speedDiff == 0)
              const Text("Geschwindigkeit halten."),
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
