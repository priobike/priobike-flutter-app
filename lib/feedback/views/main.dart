import 'package:flutter/material.dart';
import 'package:priobike/feedback/services/feedback.dart';
import 'package:provider/provider.dart';

class FeedbackView extends StatefulWidget {
  const FeedbackView({Key? key}) : super(key: key);

  @override 
  FeedbackViewState createState() => FeedbackViewState();
}

class FeedbackViewState extends State<FeedbackView> {
  /// The associated feedback service, which is injected by the provider.
  late FeedbackService feedbackService;

  @override
  void didChangeDependencies() {
    feedbackService = Provider.of<FeedbackService>(context);
    super.didChangeDependencies();
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(body: Container());
  }
}