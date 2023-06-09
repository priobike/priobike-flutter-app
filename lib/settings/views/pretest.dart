import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/lock.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/positioning/views/location_access_denied_dialog.dart';
import 'package:priobike/settings/models/test.dart';
import 'package:vibration/vibration.dart';
import 'package:wearable_communicator/wearable_communicator.dart';

const audioPath = "sounds/ding.mp3";

class PretestView extends StatefulWidget {
  final String title;
  final String user;
  final TestType testType;

  const PretestView({Key? key, required this.title, required this.user, required this.testType}) : super(key: key);

  @override
  PretestViewState createState() => PretestViewState();
}

class PretestViewState extends State<PretestView> {
  /// The associated position service, which is injected by the provider.
  late Positioning positioning;

  /// Bool that holds the synced state.
  bool synced = false;

  /// Bool that holds the test started state.
  bool testStarted = false;

  /// Bool that holds the test done state.
  bool testDone = false;

  /// Timer that is used for the test.
  Timer? _timer;

  /// Int that holds the current minute of the test.
  int minute = 0;

  /// Int that holds the second for the timer.
  int second = 5;

  /// Int that counts the number of outputs.
  int outputCounter = 0;

  /// Minimum Offset off outputs.
  final int minOffset = 20;

  /// The last Tick with an output action.
  int lastTick = 0;

  /// The current probability;
  int currentProb = 0;

  /// Random Generator.
  Random random = Random();

  /// Bool that holds the state if the phone has a vibrator.
  bool hasVibrator = false;

  final textController = TextEditingController();

  Function? stopListening;

  /// The current test.
  late Test test;

  Lock lock = Lock(milliseconds: 1000);

  final AudioPlayer audioPlayer1 = AudioPlayer();
  final AudioPlayer audioPlayer2 = AudioPlayer();
  final AudioPlayer audioPlayer3 = AudioPlayer();

  @override
  void initState() {
    super.initState();

    checkVibratorAvailable();

    positioning = getIt<Positioning>();

    // Start searching for gps positions.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await positioning.startGeolocation(
        onNoPermission: () {
          Navigator.of(context).pop();
          showLocationAccessDeniedDialog(context, positioning.positionSource);
        },
        onNewPosition: () async {},
      );
    });

    if (widget.title.contains("Phone")) {
      setState(() {
        synced = true;
      });

      startCountdown();
    } else {
      // Start listening for wear messages.
      _startListening();

      _onSendStart();
    }

    // Init test.
    test = Test(
      user: widget.user,
      date: DateTime.now().toIso8601String(),
      inputs: [],
      outputs: [],
      testType: widget.testType,
    );
  }

  Future<void> checkVibratorAvailable() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != null && hasVibrator) {
      setState(() {
        this.hasVibrator = true;
      });
    }
  }

  Future<void> _startListening() async {
    WearableListener.listenForMessage((msg) {
      Map<String, dynamic> data = jsonDecode(msg);
      if (data["status"] != null && data["status"] == "ready") {
        setState(() {
          synced = true;
        });

        startCountdown();
      }
    });
  }

  void _onSendStart() {
    WearableCommunicator.sendMessage({
      "testType": widget.testType.description,
    });
  }

  void _sendOutput(InputType inputType) {
    WearableCommunicator.sendMessage({
      "play": inputType.description,
    });
  }

  void _sendStop() {
    WearableCommunicator.sendMessage({
      "stop": true,
    });
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    _timer?.cancel();
    positioning.stopGeolocation();
    stopListening != null ? stopListening!() : null;
  }

  /// The Widget that displays syncing.
  Widget syncView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SmallVSpace(),
          Content(
            context: context,
            text: "Syncing...",
          )
        ],
      ),
    );
  }

  void startCountdown() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        setState(() {
          second = 5 - timer.tick;
        });
        if (second == -1) {
          _timer?.cancel();
          startTestTimer();
          setState(() {
            testStarted = true;
            minute = 5;
            second = 0;
          });
        }
      },
    );
  }

  void startTestTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) async {
        setState(() {
          minute = (5 - (timer.tick / 60)).toInt();
          second = (60 - timer.tick % 60) % 60;
        });

        // Check if output needs to be played.
        if (checkOutput(timer.tick)) {
          // Play output.
          playOutput();
        }

        if (timer.tick == 300) {
          _timer?.cancel();
          setState(() {
            testDone = true;
          });
          saveTestData();
        }
      },
    );
  }

  bool checkOutput(int tick) {
    if (tick >= (lastTick + minOffset)) {
      if (random.nextInt(100) < currentProb && outputCounter < 10) {
        setState(() {
          currentProb = 0;
          outputCounter += 1;
          lastTick = tick;
        });
        return true;
      } else {
        setState(() {
          currentProb += 5;
        });
        return false;
      }
    }
    return false;
  }

  void playOutput() async {
    // Random faster or slower.
    InputType inputType = random.nextInt(2) == 1 ? InputType.faster : InputType.slower;

    switch (widget.testType) {
      case TestType.wearVibrationInterval:
        _sendOutput(inputType);
        break;
      case TestType.wearVibrationContinuous:
        _sendOutput(inputType);
        break;
      case TestType.wearAudioInterval:
        _sendOutput(inputType);
        break;
      case TestType.wearAudioContinuous:
        _sendOutput(inputType);
        break;
      case TestType.phoneAudioInterval:
        playPhoneAudioInterval(inputType);
        break;
      case TestType.phoneAudioContinuous:
        playPhoneAudioContinuous(inputType);
        break;
      case TestType.phoneVibrationInterval:
        playPhoneVibrationInterval(inputType);
        break;
      case TestType.phoneVibrationContinuous:
        playPhoneVibrationContinuous(inputType);
        break;
    }
    // Add output to data.
    test.outputs.add(
      TestData(
          inputType: inputType,
          timestamp: DateTime.now().toIso8601String(),
          lat: positioning.lastPosition?.latitude ?? -1,
          lon: positioning.lastPosition?.longitude ?? -1),
    );
  }

  void playPhoneVibrationContinuous(InputType inputType) {
    if (hasVibrator) {
      if (inputType == InputType.faster) {
        // Vibrate with high frequency.
        Vibration.vibrate(pattern: [500, 250, 250, 250, 250, 250]);
      } else {
        // Vibrate with low frequency.
        Vibration.vibrate(pattern: [500, 500, 750, 500, 750, 500]);
      }
    }
  }

  void playPhoneVibrationInterval(InputType inputType) {
    if (hasVibrator) {
      if (inputType == InputType.faster) {
        // Vibrate with high frequency.
        Vibration.vibrate(pattern: [500, 500, 250, 250, 150, 150]);
      } else {
        // Vibrate with low frequency.
        Vibration.vibrate(pattern: [500, 500, 750, 500, 1000, 500]);
      }
    }
  }

  Future<void> playPhoneAudioContinuous(InputType inputType) async {
    if (inputType == InputType.faster) {
      // Audio fast.
      audioPlayer1.play(AssetSource(audioPath));
      await Future.delayed(const Duration(milliseconds: 750));
      audioPlayer2.play(AssetSource(audioPath));
      await Future.delayed(const Duration(milliseconds: 750));
      audioPlayer3.play(AssetSource(audioPath));
    } else {
      // Audio slow.
      audioPlayer1.play(AssetSource(audioPath));
      await Future.delayed(const Duration(milliseconds: 2000));
      audioPlayer2.play(AssetSource(audioPath));
      await Future.delayed(const Duration(milliseconds: 2000));
      audioPlayer3.play(AssetSource(audioPath));
    }
  }

  Future<void> playPhoneAudioInterval(InputType inputType) async {
    if (inputType == InputType.faster) {
      // Audio fast.
      audioPlayer1.play(AssetSource(audioPath));
      await Future.delayed(const Duration(milliseconds: 1000));
      audioPlayer2.play(AssetSource(audioPath));
      await Future.delayed(const Duration(milliseconds: 500));
      audioPlayer3.play(AssetSource(audioPath));
    } else {
      // Audio slow.
      audioPlayer1.play(AssetSource(audioPath));
      await Future.delayed(const Duration(milliseconds: 1500));
      audioPlayer2.play(AssetSource(audioPath));
      await Future.delayed(const Duration(milliseconds: 2000));
      audioPlayer3.play(AssetSource(audioPath));
    }
  }

  Future<void> saveTestData() async {
    // Save data in File on phone.
    await writeJson(test.toJson().toString());
    // Stop the test on watch.
    if (widget.title.contains("Phone")) {
      _sendStop();
    }
  }

  Future<File> writeJson(String json) async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.
      await Permission.storage.request();
    }

    Directory directory = Directory("/storage/emulated/0/Download/results");

    final exPath = directory.path;
    await Directory(exPath).create(recursive: true);

    File file = File('$exPath/result_${widget.user}_${test.date.split(":")[0]}.txt');

    // Write the data in the file.
    return await file.writeAsString(json);
  }

  /// The Widget that displays the Test.
  Widget testView() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: testStarted
          ? (testDone
              ? Center(
                  child: Header(context: context, text: "Test Beendet!"),
                )
              : Column(
                  children: [
                    Expanded(
                      child: BigIconButton(
                        icon: Icons.keyboard_double_arrow_up_rounded,
                        iconSize: 128,
                        fillColor: lock.timer != null && lock.timer!.isActive ? Colors.grey : CI.green,
                        splashColor: Colors.white,
                        onPressed: () {
                          lock.run(() {
                            ToastMessage.showSuccess("Schneller");

                            // Add user input.
                            test.inputs.add(
                              TestData(
                                  inputType: InputType.faster,
                                  timestamp: DateTime.now().toIso8601String(),
                                  lat: positioning.lastPosition?.latitude ?? -1,
                                  lon: positioning.lastPosition?.longitude ?? -1),
                            );
                          });
                        },
                        boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                      ),
                    ),
                    const SmallVSpace(),
                    BoldSubHeader(text: '$minute : ${second < 10 ? "0" : ""}$second', context: context),
                    const SmallVSpace(),
                    Expanded(
                      child: BigIconButton(
                        icon: Icons.keyboard_double_arrow_down_rounded,
                        iconSize: 128,
                        fillColor: lock.timer != null && lock.timer!.isActive ? Colors.grey : CI.red,
                        splashColor: Colors.white,
                        onPressed: () {
                          lock.run(() {
                            ToastMessage.showSuccess("Langsamer!");

                            // Add user input.
                            test.inputs.add(
                              TestData(
                                  inputType: InputType.slower,
                                  timestamp: DateTime.now().toIso8601String(),
                                  lat: positioning.lastPosition?.latitude ?? -1,
                                  lon: positioning.lastPosition?.longitude ?? -1),
                            );
                          });
                        },
                        boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                      ),
                    ),
                  ],
                ))
          : Center(
              child: Header(
                context: context,
                fontSize: 56,
                text: second == 0 ? "Start!" : second.toString(),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: WillPopScope(
        onWillPop: () async {
          _timer?.cancel();
          _sendStop();
          return true;
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    AppBackButton(onPressed: () {
                      _timer?.cancel();
                      _sendStop();
                      Navigator.pop(context);
                    }),
                    const HSpace(),
                    Content(text: widget.title, context: context),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    child: synced ? testView() : syncView(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
