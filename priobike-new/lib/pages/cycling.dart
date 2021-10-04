import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    Wakelock.enable();
    app = Provider.of<AppService>(context);
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(children: [
            const Text("Jetzt wird gerade gefahren"),
            app.currentRecommendation != null
                ? SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          "${app.currentRecommendation?.label}",
                        ),
                        Text(
                          "Countdown: ${app.currentRecommendation?.countdown}s",
                        ),
                        Text(
                          "Distanz: ${app.currentRecommendation?.distance?.toStringAsFixed(0)}m",
                        ),
                        Text(
                          "green: ${app.currentRecommendation?.green}",
                        ),
                        Text(
                          "SpeedRec: ${app.currentRecommendation?.speedRec}",
                        ),
                        Text(
                          "SpeedDiff: ${app.currentRecommendation?.speedDiff}",
                        ),
                        Text(
                          "error: ${app.currentRecommendation?.error}",
                        ),
                        Text(
                          "message: ${app.currentRecommendation?.errorMessage}",
                        ),
                      ],
                    ),
                  )
                : const Text("Warte auf Empfehlung vom Server"),
            ElevatedButton(
              child: const Text('Fahrt beenden'),
              onPressed: () {
                Navigator.pushReplacementNamed(context, Routes.summary);
              },
            ),
          ]),
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
