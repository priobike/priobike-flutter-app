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

  void _onSend() {
    WearableCommunicator.sendMessage({
      "text": textController.text,
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
                  title: "Start Wear Vibration Test",
                  icon: Icons.start,
                  callback: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PretestView(
                        title: "Wear Vibration Test",
                        user: textController.text,
                        testType: TestType.wearVibration,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SettingsElement(
                  title: "Start Phone Vibration Test",
                  icon: Icons.start,
                  callback: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PretestView(
                        title: "Phone Vibration Test",
                        user: textController.text,
                        testType: TestType.phoneVibration,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SettingsElement(
                  title: "Start Wear Audio Test",
                  icon: Icons.start,
                  callback: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PretestView(
                        title: "Wear Audio Test",
                        user: textController.text,
                        testType: TestType.wearAudio,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SettingsElement(
                  title: "Start Phone Audio Test",
                  icon: Icons.start,
                  callback: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PretestView(
                        title: "Phone Audio Test",
                        user: textController.text,
                        testType: TestType.phoneAudio,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
