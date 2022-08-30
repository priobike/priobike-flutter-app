import 'package:flutter/material.dart';
import 'package:priobike/common/colors.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/feedback/services/feedback.dart';
import 'package:priobike/feedback/views/stars.dart';
import 'package:priobike/feedback/views/text.dart';
import 'package:priobike/logging/toast.dart';
import 'package:provider/provider.dart';

class FeedbackView extends StatefulWidget {
  /// A callback that will be called when the user has submitted feedback.
  final Future<void> Function(BuildContext context) onSubmitted;

  /// A boolean indicating if a back button should be shown.
  final bool showBackButton;

  const FeedbackView({
    required this.onSubmitted,
    this.showBackButton = false,
    Key? key
  }) : super(key: key);

  @override 
  FeedbackViewState createState() => FeedbackViewState();
}

class FeedbackViewState extends State<FeedbackView> {
  /// The associated feedback service, which is injected by the provider.
  late FeedbackService feedbackService;

  /// Submit feedback.
  Future<void> submit(BuildContext context) async {
    // Send the feedback and reset the feedback service.
    if (feedbackService.willSendFeedback) {
      await feedbackService.send(context);
      ToastMessage.showSuccess("Danke für Dein Feedback!");
    }
    await feedbackService.reset();

    // Call the callback.
    await widget.onSubmitted(context);
  }

  @override
  void didChangeDependencies() {
    feedbackService = Provider.of<FeedbackService>(context);
    super.didChangeDependencies();
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return Scaffold(body: 
      Container(
        color: AppColors.lightGrey,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Sende Feedback...", style: TextStyle(fontSize: 16)),
          ]
        ),
      ),
    );
  }

  @override 
  Widget build(BuildContext context) {
    if (feedbackService.isSendingFeedback) return renderLoadingIndicator();

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(body: Stack(children: [
        Container(
          color: AppColors.lightGrey,
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 128),
                if (widget.showBackButton) Row(children: [
                  AppBackButton(icon: Icons.chevron_left, onPressed: () => Navigator.pop(context)),
                  const HSpace(),
                  SubHeader(text: "Feedback"),
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
                BigButton(
                  icon: feedbackService.willSendFeedback ? Icons.send : Icons.check,
                  label: feedbackService.willSendFeedback ? "Senden" : "Fertig",
                  onPressed: () => submit(context),
                ),
                const SizedBox(height: 128),
              ],
            ),
          ),
        ),
      ])),
    );
  }
}