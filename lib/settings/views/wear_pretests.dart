import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/settings/models/test.dart';
import 'package:priobike/settings/views/main.dart';
import 'package:priobike/settings/views/pretest.dart';
import 'package:wearable_communicator/wearable_communicator.dart';

class WearPretestsView extends StatefulWidget {
  const WearPretestsView({Key? key}) : super(key: key);

  @override
  WearPretestsViewState createState() => WearPretestsViewState();
}

class WearPretestsViewState extends State<WearPretestsView> {
  String messageReceived = "";

  final textController = TextEditingController();

  Function? stopListening;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  Future<void> _startListening() async {
    WearableListener.listenForMessage((msg) {
      setState(() {
        messageReceived = msg;
      });
    });
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    stopListening != null ? stopListening!() : null;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: ListView(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  AppBackButton(onPressed: () => Navigator.pop(context)),
                  const HSpace(),
                  SubHeader(text: "Wear Pretests", context: context),
                ],
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextFormField(
                  controller: textController,
                  maxLength: 20,
                  decoration: const InputDecoration(hintText: 'Testender'),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SettingsElement(
                  title: "Start Wear Vibration(interval) Test",
                  icon: Icons.start,
                  callback: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PretestView(
                        title: "Wear Vibration(interval) Test",
                        user: textController.text,
                        testType: TestType.wearVibrationInterval,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SettingsElement(
                  title: "Start Wear Vibration(continuous) Test",
                  icon: Icons.start,
                  callback: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PretestView(
                        title: "Wear Vibration(continuous) Test",
                        user: textController.text,
                        testType: TestType.wearVibrationContinuous,
                      ),
                    ),
                  ),
                ),
              ),
              const VSpace(),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SettingsElement(
                  title: "Start Phone Vibration(Interval) Test",
                  icon: Icons.start,
                  callback: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PretestView(
                        title: "Phone Vibration(Interval) Test",
                        user: textController.text,
                        testType: TestType.phoneVibrationInterval,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SettingsElement(
                  title: "Start Phone Vibration(Continuous) Test",
                  icon: Icons.start,
                  callback: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PretestView(
                        title: "Phone Vibration(Continuous) Test",
                        user: textController.text,
                        testType: TestType.phoneVibrationContinuous,
                      ),
                    ),
                  ),
                ),
              ),
              const VSpace(),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SettingsElement(
                  title: "Start Wear Audio(Interval) Test",
                  icon: Icons.start,
                  callback: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PretestView(
                        title: "Wear Audio(Interval) Test",
                        user: textController.text,
                        testType: TestType.wearAudioInterval,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SettingsElement(
                  title: "Start Wear Audio(Continuous) Test",
                  icon: Icons.start,
                  callback: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PretestView(
                        title: "Wear Audio(Continuous) Test",
                        user: textController.text,
                        testType: TestType.wearAudioContinuous,
                      ),
                    ),
                  ),
                ),
              ),
              const VSpace(),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SettingsElement(
                  title: "Start Phone Audio(Interval) Test",
                  icon: Icons.start,
                  callback: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PretestView(
                        title: "Phone Audio(Interval) Test",
                        user: textController.text,
                        testType: TestType.phoneAudioInterval,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SettingsElement(
                  title: "Start Phone Audio(Continuous) Test",
                  icon: Icons.start,
                  callback: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PretestView(
                        title: "Phone Audio(Continuous) Test",
                        user: textController.text,
                        testType: TestType.phoneAudioContinuous,
                      ),
                    ),
                  ),
                ),
              ),
              const VSpace(),
            ],
          ),
        ),
      ),
    );
  }
}
