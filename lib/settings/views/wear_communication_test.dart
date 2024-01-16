import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';

class WearCommunicationTestView extends StatefulWidget {
  const WearCommunicationTestView({Key? key}) : super(key: key);

  @override
  WearCommunicationTestViewState createState() => WearCommunicationTestViewState();
}

class WearCommunicationTestViewState extends State<WearCommunicationTestView> {
  String messageReceived = "";

  final textController = TextEditingController();

  Function? stopListening;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  Future<void> _startListening() async {
    // WearableListener.listenForMessage((msg) {
    //   setState(() {
    //     messageReceived = msg;
    //   });
    // });
  }

  void _onSend() {
    // WearableCommunicator.sendMessage({
    //   "text": textController.text,
    // });
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  AppBackButton(onPressed: () => Navigator.pop(context)),
                  const HSpace(),
                  SubHeader(text: "Wear OS Communication test", context: context),
                ],
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BoldContent(text: "Incoming Data", context: context),
                    const SizedBox(height: 8),
                    BoldContent(text: messageReceived, context: context),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: textController,
                      maxLength: 20,
                      decoration: const InputDecoration(hintText: 'Message text ...'),
                    ),
                    const SizedBox(height: 8),
                    BigButtonPrimary(
                        label: "Send",
                        onPressed: _onSend,
                        boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
