import 'package:flutter/material.dart';
import 'package:priobike/services/app.dart';
import 'package:provider/provider.dart';

import '../models/recommendation.dart';
import '../utils/routes.dart';

class MinimalRecommendationCyclingView extends StatefulWidget {
  const MinimalRecommendationCyclingView({Key? key}) : super(key: key);

  @override
  State<MinimalRecommendationCyclingView> createState() =>
      _MinimalRecommendationCyclingViewState();
}

class _MinimalRecommendationCyclingViewState
    extends State<MinimalRecommendationCyclingView> {
  late AppService app;

  @override
  Widget build(BuildContext context) {
    app = Provider.of<AppService>(context);

    Recommendation recommendation = app.currentRecommendation!;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            if (recommendation.speedDiff > 0)
              const Icon(
                Icons.arrow_upward,
                color: Colors.red,
                size: 250.0,
              ),
            if (recommendation.speedDiff < 0)
              const Icon(
                Icons.arrow_downward,
                color: Colors.blue,
                size: 250.0,
              ),
            if (recommendation.speedDiff == 0)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 250.0,
              ),
            if (recommendation.speedDiff != 0)
              Text(
                "${recommendation.speedDiff > 0 ? "+" : ""}${(recommendation.speedDiff * 3.6).toStringAsFixed(0)} km/h",
                style: const TextStyle(fontSize: 60),
              ),
            if (recommendation.speedDiff > 0)
              const Text(
                "schneller fahren",
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white54,
                ),
              ),
            if (recommendation.speedDiff < 0)
              const Text(
                "langsamer fahren",
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white54,
                ),
              ),
            if (recommendation.speedDiff == 0)
              const Text(
                "Geschwindigkeit halten.",
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
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
