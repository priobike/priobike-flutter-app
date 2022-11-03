import 'package:flutter/material.dart' hide Feedback;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/feedback/services/feedback.dart';
import 'package:priobike/feedback/views/stars.dart';
import 'package:priobike/feedback/views/text.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/tracking/views/send.dart';
import 'package:provider/provider.dart';

class FeedbackView extends StatefulWidget {
  /// A callback that will be called when the user has submitted feedback.
  final Future<void> Function(BuildContext context) onSubmitted;

  /// A boolean indicating if a back button should be shown.
  final bool showBackButton;

  const FeedbackView({required this.onSubmitted, this.showBackButton = false, Key? key}) : super(key: key);

  @override
  FeedbackViewState createState() => FeedbackViewState();
}

class FeedbackViewState extends State<FeedbackView> {
  /// The associated tracking service, which is injected by the provider.
  late Tracking tracking;

  /// The associated feedback service, which is injected by the provider.
  late Feedback feedback;

  /// Submit feedback.
  Future<void> submit(BuildContext context) async {
    var didSendSomething = false;

    // Send the feedback and reset the feedback service.
    if (feedback.willSendFeedback) {
      didSendSomething = didSendSomething || await feedback.send(context);
    }
    await feedback.reset();

    // Send the tracking data and reset the tracking service.
    if (tracking.willSendTrack && tracking.canSendTrack) {
      didSendSomething = didSendSomething || await tracking.send(context);
    }
    await tracking.reset();

    if (didSendSomething) {
      ToastMessage.showSuccess("Danke für's Testen!");
    }

    // Call the callback.
    await widget.onSubmitted(context);
  }

  @override
  void didChangeDependencies() {
    tracking = Provider.of<Tracking>(context);
    feedback = Provider.of<Feedback>(context);
    super.didChangeDependencies();
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        width: MediaQuery.of(context).size.width,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Sende Feedback...", style: TextStyle(fontSize: 16)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (feedback.isSendingFeedback || tracking.isSendingTrack) {
      return renderLoadingIndicator();
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
          body: Stack(children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: SafeArea(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                if (widget.showBackButton)
                  Row(children: [
                    AppBackButton(onPressed: () => Navigator.pop(context)),
                    const HSpace(),
                    SubHeader(text: "Feedback", context: context),
                  ]),
                const VSpace(),
                const Divider(),
                const VSpace(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: StarRatingView(text: "Feedback zur App"),
                ),
                const VSpace(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: TextFeedbackView(text: "Was können wir verbessern?"),
                ),
                const VSpace(),
                const Divider(),
                const VSpace(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: SendTrackingView(),
                ),
                const VSpace(),
                const Divider(),
                const VSpace(),
                BigButton(
                  iconColor: Colors.white,
                  icon: feedback.willSendFeedback || (tracking.willSendTrack && tracking.canSendTrack)
                      ? Icons.send
                      : Icons.check,
                  label: feedback.willSendFeedback || (tracking.willSendTrack && tracking.canSendTrack)
                      ? "Senden"
                      : "Fertig",
                  onPressed: () => submit(context),
                ),
                const SizedBox(height: 128),
              ],
            )),
          ),
        ),
      ])),
    );
  }
}
