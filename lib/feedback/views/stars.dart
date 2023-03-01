import 'dart:math';

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

  const StarRatingView({required this.text, Key? key}) : super(key: key);

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

  /// A custom Path to paint stars.
  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step), halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
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
        Small(text: widget.text, context: context, color: Colors.white),
        const SizedBox(height: 2),
        LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.maxWidth / 5;
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
                          HSLColor.fromColor(Colors.yellow).withLightness(0.5).toColor(),
                          HSLColor.fromColor(Colors.yellow).withLightness(0.6).toColor(),
                          HSLColor.fromColor(Colors.yellow).withLightness(0.7).toColor(),
                        ],
                        particleDrag: 0.2,
                        createParticlePath: drawStar,
                        numberOfParticles: (i - 1) * 5 + 1,
                      ),
                      GestureDetector(
                        onTap: () => onStarTapped(i),
                        child: AnimatedCrossFade(
                          duration: const Duration(milliseconds: 500),
                          firstCurve: Curves.bounceIn,
                          secondCurve: Curves.bounceIn,
                          crossFadeState: rating >= i ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          firstChild: Icon(
                            Icons.star_rounded,
                            size: size,
                            color: Colors.yellow,
                          ),
                          secondChild: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.star_border_rounded,
                              size: size - 8,
                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
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
