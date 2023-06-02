import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/positioning/views/location_access_denied_dialog.dart';
import 'package:priobike/settings/models/test.dart';
import 'package:wearable_communicator/wearable_communicator.dart';

class PretestView extends StatefulWidget {
  final String title;
  final String user;
  final TestType testType;

  const PretestView(
      {Key? key,
      required this.title,
      required this.user,
      required this.testType})
      : super(key: key);

  @override
  PretestViewState createState() => PretestViewState();
}

class PretestViewState extends State<PretestView> {
  /// The associated position service, which is injected by the provider.
  late Positioning positioning;

  bool synced = false;

  bool testStarted = false;

  bool testDone = false;

  Timer? _timer;

  int minute = 0;

  int second = 5;

  final textController = TextEditingController();

  Function? stopListening;

  late Test test;

  @override
  void initState() {
    super.initState();

    positioning = getIt<Positioning>();

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
      synced = true;
      startCountdown();
    }
    _startListening();

    // Init test.
    test = Test(
      user: widget.user,
      date: DateTime.now().toIso8601String(),
      inputs: [],
      outputs: [],
      testType: widget.testType,
    );

    /// TODO send message to watch and listen for response => syncing Test.
  }

  Future<void> _startListening() async {
    WearableListener.listenForMessage((msg) {
      setState(() {});
    });
  }

  void _onSend() {
    WearableCommunicator.sendMessage({
      "text": textController.text,
    });
  }

  @override
  Future<void> dispose() async {
    super.dispose();
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
      (Timer timer) {
        setState(() {
          minute = (5 - (timer.tick / 60)).toInt();
          second = (60 - timer.tick % 60) % 60;
        });
        if (timer.tick == 10) {
          _timer?.cancel();
          setState(() {
            testDone = true;
            print(test.toJson());
          });
          saveTestData();
        }
      },
    );
  }

  Future<void> saveTestData() async {
    var file = await writeJson(test.toJson().toString());
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

    File file = File(
        '$exPath/result_${widget.user}_${test.date.split(":")[0]}.txt');

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
                        fillColor: CI.green,
                        splashColor: Colors.white,
                        onPressed: () {
                          ToastMessage.showSuccess("Schneller");
                        },
                        boxConstraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width),
                      ),
                    ),
                    const SmallVSpace(),
                    BoldSubHeader(
                        text: '$minute : ${second < 10 ? "0" : ""}$second',
                        context: context),
                    const SmallVSpace(),
                    Expanded(
                      child: BigIconButton(
                        icon: Icons.keyboard_double_arrow_down_rounded,
                        iconSize: 128,
                        fillColor: CI.red,
                        splashColor: Colors.white,
                        onPressed: () {
                          ToastMessage.showSuccess("Langsamer!");

                          if (positioning.lastPosition != null) {
                            // Add user input.
                            test.inputs.add(
                              TestData(
                                  inputType: InputType.slower,
                                  timestamp: DateTime.now().toIso8601String(),
                                  lat: positioning.lastPosition!.latitude,
                                  lon: positioning.lastPosition!.longitude),
                            );
                          }
                        },
                        boxConstraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width),
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
      value: Theme.of(context).brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  AppBackButton(onPressed: () => Navigator.pop(context)),
                  const HSpace(),
                  SubHeader(text: widget.title, context: context),
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
    );
  }
}
