import 'package:flutter/material.dart' hide Feedback;
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/feedback/models/question.dart';
import 'package:priobike/feedback/services/feedback.dart';
import 'package:provider/provider.dart';

/// A view with 5 stars to rate the current ride.
class StarRatingView extends StatefulWidget {
  /// The text of the question.
  final String text;

  const StarRatingView({required this.text, Key? key}) : super(key: key);

  @override
  StarRatingViewState createState() => StarRatingViewState();
}

class StarRatingViewState extends State<StarRatingView> {
  /// The feedback service, which is injected by the provider.
  late Feedback feedback;

  /// The current rating.
  int rating = 0;

  @override
  void didChangeDependencies() {
    feedback = Provider.of<Feedback>(context);
    super.didChangeDependencies();
  }

  /// A callback that is called when a star is tapped.
  Future<void> onStarTapped(int index) async {
    // Set the rating.
    setState(() {
      rating = index;
    });

    // Save the rating.
    final question = Question(
      text: widget.text,
      imageData: null, // Star ratings do not have images.
      answer: "$rating Stars",
    );

    await feedback.update(id: question.text, question: question);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Small(text: widget.text, context: context),
        const SmallVSpace(),
        LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.maxWidth / 5;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  GestureDetector(
                    onTap: () => onStarTapped(i),
                    child: Icon(
                      i <= rating ? Icons.star : Icons.star_border,
                      size: size,
                      color: const Color.fromRGBO(255, 215, 0, 1),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
