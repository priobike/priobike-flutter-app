import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
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
const List<String> standaloneImages = [];

// Audios.
const audioIntervalFaster = "sounds/interval_faster.mp3";
const audioIntervalSlower = "sounds/interval_slower.mp3";
const audioInfo = "sounds/info.mp3";
const audioSuccess = "sounds/success.mp3";

class WearTutorialView extends StatefulWidget {
  const WearTutorialView({Key? key}) : super(key: key);

  @override
  WearTutorialViewState createState() => WearTutorialViewState();
}

class WearTutorialViewState extends State<WearTutorialView> {
  bool signalPlayed = false;

  int tutorialState = 0;

  late Settings settings;

  late List<String> usedImages = [];

  final AudioPlayer audioPlayer1 = AudioPlayer();
  final AudioPlayer audioPlayer2 = AudioPlayer();

  /// The timer used for the signal loops.
  Timer? timer;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    settings = getIt<Settings>();
    settings.addListener(update);

    if (settings.watchStandalone) {
      usedImages = standaloneImages;
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
  }

  @override
  void dispose() {
    super.dispose();
    settings.removeListener(update);
  }

  playSignal() {
    /// Decide which signal to play.
    if (settings.watchStandalone) return;

    switch (settings.rideAssistMode) {
      case RideAssistMode.none:
        return;
      case RideAssistMode.easy:
        if (settings.modalityMode == ModalityMode.vibration) {
        } else {
          // Audio.
          // Decide which.
          if (tutorialState == 0) {
            audioPlayer1.play(AssetSource(audioInfo));
            timer = Timer.periodic(const Duration(milliseconds: 5000), (timer) {
              audioPlayer2.play(AssetSource(audioInfo));
            });
          }
          if (tutorialState == 1) {
            audioPlayer1.play(AssetSource(audioSuccess));
            timer = Timer.periodic(const Duration(milliseconds: 5000), (timer) {
              audioPlayer2.play(AssetSource(audioSuccess));
            });
          }
          if (tutorialState == 2) {
            audioPlayer1.play(AssetSource(audioInfo));
            timer = Timer.periodic(const Duration(milliseconds: 5000), (timer) {
              audioPlayer2.play(AssetSource(audioInfo));
            });
          }
        }
        break;
      case RideAssistMode.continuous:
        if (settings.modalityMode == ModalityMode.vibration) {
        } else {
          // Audio.
          // Decide which.
          if (tutorialState == 0) {
            // Nothing.
          }
          if (tutorialState == 1) {
            audioPlayer1.play(AssetSource(audioInfo));
            timer = Timer.periodic(const Duration(milliseconds: 4000), (timer) {
              audioPlayer2.play(AssetSource(audioInfo));
            });
          }
          if (tutorialState == 2) {
            audioPlayer1.play(AssetSource(audioInfo));
            timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
              audioPlayer2.play(AssetSource(audioInfo));
            });
          }
        }
        break;
      case RideAssistMode.interval:
        if (settings.modalityMode == ModalityMode.vibration) {
        } else {
          // Audio.
          // Decide which.
          if (tutorialState == 0) {
            audioPlayer1.play(AssetSource(audioSuccess));
            timer = Timer.periodic(const Duration(milliseconds: 5000), (timer) {
              audioPlayer2.play(AssetSource(audioSuccess));
            });
          }
          if (tutorialState == 1) {
            audioPlayer1.play(AssetSource(audioIntervalSlower));
            timer = Timer.periodic(const Duration(milliseconds: 5000), (timer) {
              audioPlayer2.play(AssetSource(audioIntervalSlower));
            });
          }
          if (tutorialState == 2) {
            audioPlayer1.play(AssetSource(audioIntervalFaster));
            timer = Timer.periodic(const Duration(milliseconds: 5000), (timer) {
              audioPlayer2.play(AssetSource(audioIntervalFaster));
            });
          }
        }
        break;
    }
  }

  stopPlaySignal() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
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
