

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/feedback/models/question.dart';
import 'package:priobike/feedback/services/feedback.dart';
import 'package:provider/provider.dart';

/// A view with a text input field to provide textual feedback.
class TextFeedbackView extends StatefulWidget {
  /// The text of the question.
  final String text;

  const TextFeedbackView({required this.text, Key? key}) : super(key: key);

  @override
  TextFeedbackViewState createState() => TextFeedbackViewState();
}

class TextFeedbackViewState extends State<TextFeedbackView> {
  /// The feedback service, which is injected by the provider.
  late FeedbackService feedbackService;

  /// The current text.
  var userInput = "";

  @override
  void didChangeDependencies() {
    feedbackService = Provider.of<FeedbackService>(context);
    super.didChangeDependencies();
  }

  /// A callback that is called when the text changes.
  Future<void> onTextChanged(String text) async {
    // Set the text.
    setState(() {
      userInput = text;
    });

    // Save the text.
    final question = Question(
      text: widget.text,
      imageData: null, // Text feedback does not have images.
      answer: text,
    );

    await feedbackService.update(id: question.text, question: question);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Small(text: widget.text),
        const SmallVSpace(),
        TextField(
          keyboardType: TextInputType.multiline,
          maxLines: null,
          maxLength: 1000,
          onChanged: onTextChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
            hintText: "Dein persönliches Feedback",
          ),
        ),
      ],
    );
  }
}
