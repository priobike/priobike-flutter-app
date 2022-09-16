import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/ride/views/button.dart';
import 'package:provider/provider.dart';

class MinimalRecommendationCyclingView extends StatefulWidget {
  const MinimalRecommendationCyclingView({Key? key}) : super(key: key);

  @override
  State<MinimalRecommendationCyclingView> createState() => _MinimalRecommendationCyclingViewState();
}

class _MinimalRecommendationCyclingViewState extends State<MinimalRecommendationCyclingView> {
  late Ride app;

  @override
  Widget build(BuildContext context) {
    app = Provider.of<Ride>(context);
    if (app.currentRecommendation == null) return Container();

    final recommendation = app.currentRecommendation!;

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
              Header(
                text: "schneller fahren",
                context: context,
              ),
            if (recommendation.speedDiff < 0)
              Header(
                text: "langsamer fahren",
                context: context,
              ),
            if (recommendation.speedDiff == 0)
              Header(
                text: "Geschwindigkeit halten.",
                context: context,
              ),
            const Spacer(),
            const SizedBox(
              width: double.infinity,
              child: CancelButton(text: "Fahrt beenden"),
            ),
          ],
        ),
      ),
    );
  }
}
