import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/services/ride_assist.dart';
import 'package:priobike/settings/models/ride_assist.dart';
import 'package:priobike/settings/services/settings.dart';

const List<String> easyImages = [
  "assets/tutorial/too_fast.png",
  "assets/tutorial/green.png",
  "assets/tutorial/too_fast.png",
];
const List<String> intervalImages = [
  "assets/tutorial/green.png",
  "assets/tutorial/too_fast.png",
  "assets/tutorial/too_slow.png",
];
const List<String> continuousImages = [
  "assets/tutorial/green.png",
  "assets/tutorial/too_fast.png",
  "assets/tutorial/too_slow.png",
];
const List<String> standaloneImages = ["assets/tutorial/watch_standalone.png"];

class WearTutorialView extends StatefulWidget {
  const WearTutorialView({Key? key}) : super(key: key);

  @override
  WearTutorialViewState createState() => WearTutorialViewState();
}

class WearTutorialViewState extends State<WearTutorialView> {
  bool signalPlayed = false;

  int tutorialState = 0;

  late Settings settings;

  late RideAssist rideAssist;

  late List<String> usedImages = [];

  /// The timer used for the signal loops.
  Timer? timer;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    settings = getIt<Settings>();
    settings.addListener(update);
    rideAssist = getIt<RideAssist>();
    rideAssist.addListener(update);

    if (settings.modalityMode == ModalityMode.vibration) {
      rideAssist.sendStart();
    }


    if (settings.rideAssistMode == RideAssistMode.easy) {
      usedImages = easyImages;
    }
    if (settings.rideAssistMode == RideAssistMode.continuous) {
      usedImages = continuousImages;
    }
    if (settings.rideAssistMode == RideAssistMode.interval) {
      usedImages = intervalImages;
    }
    if (settings.watchStandalone) {
      usedImages = standaloneImages;
    }
  }

  @override
  void dispose() {
    super.dispose();
    settings.removeListener(update);
    rideAssist.removeListener(update);
  }

  playSignal() {
    /// Decide which signal to play.
    if (settings.watchStandalone) return;

    switch (settings.rideAssistMode) {
      case RideAssistMode.none:
        return;
      case RideAssistMode.easy:
        if (tutorialState == 0) {
          rideAssist.playInfo();
          timer = Timer.periodic(const Duration(milliseconds: 5000), (timer) {
            rideAssist.playInfo();
          });
        }
        if (tutorialState == 1) {
          rideAssist.playSuccess();
          timer = Timer.periodic(const Duration(milliseconds: 5000), (timer) {
            rideAssist.playSuccess();
          });
        }
        if (tutorialState == 2) {
          rideAssist.playInfo();
          timer = Timer.periodic(const Duration(milliseconds: 5000), (timer) {
            rideAssist.playInfo();
          });
        }
        break;
      case RideAssistMode.continuous:
        if (tutorialState == 0) {
          // Nothing.
        }
        if (tutorialState == 1) {
          rideAssist.startSlowerLoop();
        }
        if (tutorialState == 2) {
          rideAssist.startFasterLoop();
        }
        break;
      case RideAssistMode.interval:
        if (tutorialState == 0) {
          rideAssist.playSuccess();
          timer = Timer.periodic(const Duration(milliseconds: 5000), (timer) {
            rideAssist.playSuccess();
          });
        }
        if (tutorialState == 1) {
          rideAssist.playSlower();
          timer = Timer.periodic(Duration(milliseconds: settings.modalityMode == ModalityMode.vibration ? 10000 : 5000),
              (timer) {
            rideAssist.playSlower();
          });
        }
        if (tutorialState == 2) {
          rideAssist.playFaster();
          timer = Timer.periodic(const Duration(milliseconds: 5000), (timer) {
            rideAssist.playFaster();
          });
        }
        break;
    }
  }

  stopPlaySignal() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }
    if (settings.rideAssistMode == RideAssistMode.continuous) {
      rideAssist.stopSignalLoop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              if (tutorialState + 1 == usedImages.length && signalPlayed) {
                stopPlaySignal();
                rideAssist.sendStop();
                Navigator.of(context).pop();
              }
              if (!signalPlayed) {
                signalPlayed = true;
                playSignal();
              } else {
                signalPlayed = false;
                tutorialState += 1;
                stopPlaySignal();
              }
            });
          },
          child: Icon(
            tutorialState + 1 == usedImages.length && signalPlayed ? Icons.close : Icons.navigate_next,
            color: Colors.white,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  AppBackButton(onPressed: () {
                    stopPlaySignal();
                    rideAssist.sendStop();
                    Navigator.pop(context);
                  }),
                  const HSpace(),
                  SubHeader(text: "Tutorial", context: context),
                ],
              ),
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: usedImages.length > tutorialState
                          ? Image(
                              image: AssetImage(usedImages[tutorialState]),
                            )
                          : Container(
                              height: MediaQuery.of(context).size.height,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
