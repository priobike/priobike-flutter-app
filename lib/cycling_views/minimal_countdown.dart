import 'package:flutter/material.dart';
import 'package:priobike/services/app.dart';
import 'package:provider/provider.dart';

import '../models/recommendation.dart';
import '../utils/routes.dart';

class MinimalCountdownCyclingView extends StatefulWidget {
  const MinimalCountdownCyclingView({Key? key}) : super(key: key);

  @override
  State<MinimalCountdownCyclingView> createState() =>
      _MinimalCountdownCyclingViewState();
}

class _MinimalCountdownCyclingViewState
    extends State<MinimalCountdownCyclingView> {
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
            Text(
              'Ampel in ${recommendation.distance.round()}m',
              style: const TextStyle(fontSize: 35),
            ),
            const Spacer(),
            Stack(children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  height: MediaQuery.of(context).size.width / 2.0,
                  width: MediaQuery.of(context).size.width / 2.0,
                  decoration: BoxDecoration(
                    color: recommendation.green
                        ? const Color.fromARGB(255, 23, 94, 30)
                        : const Color.fromARGB(255, 109, 29, 25),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.width / 2.0,
                  width: MediaQuery.of(context).size.width / 2.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 40,
                    // backgroundColor: Colors.black,
                    color: recommendation.green
                        ? const Color.fromARGB(255, 54, 222, 70)
                        : Colors.red,
                    value: recommendation.countdown / 60,
                  ),
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
