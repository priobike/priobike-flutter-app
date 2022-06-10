import 'package:flutter/material.dart';

import 'package:priobike/cycling_views/default.dart';
import 'package:priobike/cycling_views/minimal_countdown.dart';
import 'package:priobike/cycling_views/minimal_json.dart';
import 'package:priobike/cycling_views/minimal_navigation.dart';
import 'package:priobike/cycling_views/minimal_recommendation.dart';
import 'package:priobike/cycling_views/speedometer/view.dart';
import 'package:priobike/services/app.dart';

import 'package:priobike/utils/logger.dart';
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

  final PageController _pageController = PageController(
    initialPage: 0,
  );

  @override
  Widget build(BuildContext context) {
    Wakelock.enable();

    app = Provider.of<AppService>(context);

    const styleTrue = TextStyle(color: Colors.green);
    const styleFalse = TextStyle(color: Colors.red);

    return SafeArea(
      child: Scaffold(
        body: app.currentRecommendation != null
            ? PageView(
                controller: _pageController,
                scrollDirection: Axis.horizontal,
                children: const [
                  SpeedometerView(),
                  DefaultCyclingView(),
                  MinimalRecommendationCyclingView(),
                  MinimalCountdownCyclingView(),
                  MinimalNavigationCyclingView(),
                  DefaultDebugCyclingView(),
                  MinimalDebugCyclingView(),
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
