import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/feedback/models/question.dart';
import 'package:priobike/feedback/services/feedback.dart';
import 'package:priobike/main.dart';

/// A view with 5 stars to rate the current ride.
class StarRatingView extends StatefulWidget {
  /// The text of the question.
  final String text;

  /// Whether the the feedback question should be displayed.
  final bool displayQuestion;

  const StarRatingView({required this.text, required this.displayQuestion, super.key});

  @override
  StarRatingViewState createState() => StarRatingViewState();
}

class StarRatingViewState extends State<StarRatingView> {
  /// The feedback service, which is injected by the provider.
  late Feedback feedback;

  /// The confetti controllers.
  late List<ConfettiController> confettiControllers;

  /// The current rating.
  int rating = 0;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    confettiControllers = List.generate(5, (index) => ConfettiController(duration: const Duration(milliseconds: 500)));
    feedback = getIt<Feedback>();
    feedback.addListener(update);
  }

  @override
  void dispose() {
    for (final controller in confettiControllers) {
      controller.dispose();
    }
    feedback.removeListener(update);
    super.dispose();
  }

  /// A custom Path to paint confetti stripes.
  Path drawConfetti(Size size) {
    Path path = Path();
    path.addRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width / 2, size.height / 2), const Radius.circular(0)));

    return path;
  }

  /// A callback that is called when a star is tapped.
  Future<void> onStarTapped(int index) async {
    HapticFeedback.mediumImpact();

    // Play the confetti.
    confettiControllers[index - 1].play();

    // Set the rating.
    setState(
      () {
        rating = index;
      },
    );

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
        if (widget.displayQuestion) ...[
          Small(text: widget.text, context: context, color: Theme.of(context).colorScheme.tertiary),
          const SizedBox(height: 2),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.maxWidth / 6;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  Stack(
                    children: [
                      ConfettiWidget(
                        confettiController: confettiControllers[i - 1],
                        blastDirectionality: BlastDirectionality.explosive,
                        shouldLoop: false,
                        colors: [
                          HSLColor.fromColor(Theme.of(context).colorScheme.primary).withLightness(0.8).toColor(),
                          HSLColor.fromColor(Theme.of(context).colorScheme.primary).withLightness(0.9).toColor(),
                          HSLColor.fromColor(Theme.of(context).colorScheme.primary).withLightness(1).toColor(),
                        ],
                        particleDrag: 0.2,
                        createParticlePath: drawConfetti,
                        numberOfParticles: (i - 1) * 5 + 1,
                      ),
                      GestureDetector(
                        onTap: () => onStarTapped(i),
                        child: AnimatedCrossFade(
                          duration: const Duration(milliseconds: 500),
                          firstCurve: Curves.bounceIn,
                          secondCurve: Curves.bounceIn,
                          crossFadeState: rating >= i ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          firstChild: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.thumb_up_rounded,
                              size: size,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          secondChild: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.thumb_up_outlined,
                              size: size - 8,
                              color: Theme.of(context).colorScheme.onTertiary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
              ],
            );
          },
        ),
      ],
    );
  }
}
