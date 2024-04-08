import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/text.dart';

/// A view with 5 stars to rate the current ride.
class AudioRatingView extends StatefulWidget {

  const AudioRatingView({super.key});

  @override
  AudioRatingViewState createState() => AudioRatingViewState();
}

class AudioRatingViewState extends State<AudioRatingView> {
 /// The score of the 10 questions questions.
  int scoreQ1 = 0;
  int scoreQ2 = 0;
  int scoreQ3 = 0;
  int scoreQ4 = 0;
  int scoreQ5 = 0;
  int scoreQ6 = 0;
  int scoreQ7 = 0;
  int scoreQ8 = 0;
  int scoreQ9 = 0;
  int scoreQ10 = 0;

  /// The text of the 10 questions.
  String textQ1 = "Ich kann mir sehr gut vorstellen, die Sprachausgabe regelmäßig zu nutzen.";
  String textQ2 = "Ich empfinde die Sprachausgabe als unnötig komplex.";
  String textQ3 = "Ich empfinde die Sprachausgabe als einfach zu nutzen.";
  String textQ4 = "Ich denke, dass ich technischen Support brauchen würde, um die Sprachausgabe zu nutzen.";
  String textQ5 = "Ich finde, dass die verschiedenen Funktionen der Sprachausgabe gut integriert sind.";
  String textQ6 = "Ich finde, dass es in der Sprachausgabe zu viele Inkonsistenzen gibt";
  String textQ7 = "Ich kann mir vorstellen, dass die meisten Leute die Sprachausgabe schnell zu beherrschen lernen.";
  String textQ8 = "Ich empfinde die Bedienung der Sprachausgabe als sehr umständlich.";
  String textQ9 = "Ich habe mich bei der Nutzung der Sprachausgabe sehr sicher gefühlt.";
  String textQ10 = "Ich musste eine Menge Dinge lernen, bevor ich mit der Sprachausgabe arbeiten konnte";

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
  }

  /// A callback that is called when a response is tapped.
  void onResponseTapped(int questionNr, int index) {
    HapticFeedback.mediumImpact();

    // Set the rating.
    setState(
          () {
        switch (questionNr) {
          case 1:
            scoreQ1 = index;
            break;
          case 2:
            scoreQ2 = index;
            break;
          case 3:
            scoreQ3 = index;
            break;
          case 4:
            scoreQ4 = index;
            break;
          case 5:
            scoreQ5 = index;
            break;
          case 6:
            scoreQ6 = index;
            break;
          case 7:
            scoreQ7 = index;
            break;
          case 8:
            scoreQ8 = index;
            break;
          case 9:
            scoreQ9 = index;
            break;
          case 10:
            scoreQ10 = index;
            break;
        }
      },
    );

    // TODO: Save the rating
  }

  Widget getLabels() {
    return Row(
      children: [
        Small(text: "Gar nicht \n zutreffend", context: context, color: Theme.of(context).colorScheme.tertiary, textAlign: TextAlign.left),
        const Spacer(),
        Small(text: "Völlig \n zutreffend", context: context, color: Theme.of(context).colorScheme.tertiary, textAlign: TextAlign.right),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, constraints) {
            final size = (constraints.maxWidth / 5) - 8;
            return Column(
              children: [
                Content(text: "Frage 1", context: context, color: Theme.of(context).colorScheme.tertiary),
                Text(textQ1, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Radio(
                        groupValue: i,
                        value: scoreQ1,
                        onChanged: (value) {
                          setState(() {
                            onResponseTapped(1, i);
                          });
                        },
                      ),
                  ],
                ),
                getLabels(),
                const SizedBox(height: 30),
                Content(text: "Frage 2", context: context, color: Theme.of(context).colorScheme.tertiary),
                Text(textQ2, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Radio(
                        groupValue: i,
                        value: scoreQ2,
                        onChanged: (value) {
                          setState(() {
                            onResponseTapped(2, i);
                          });
                        },
                      ),
                  ],
                ),
                getLabels(),
                const SizedBox(height: 30),
                Content(text: "Frage 3", context: context, color: Theme.of(context).colorScheme.tertiary),
                Text(textQ3, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Radio(
                        groupValue: i,
                        value: scoreQ3,
                        onChanged: (value) {
                          setState(() {
                            onResponseTapped(3, i);
                          });
                        },
                      ),
                  ],
                ),
                getLabels(),
                const SizedBox(height: 30),
                Content(text: "Frage 4", context: context, color: Theme.of(context).colorScheme.tertiary),
                Text(textQ4, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Radio(
                        groupValue: i,
                        value: scoreQ4,
                        onChanged: (value) {
                          setState(() {
                            onResponseTapped(4, i);
                          });
                        },
                      ),
                  ],
                ),
                getLabels(),
                const SizedBox(height: 30),
                Content(text: "Frage 5", context: context, color: Theme.of(context).colorScheme.tertiary),
                Text(textQ5, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Radio(
                        groupValue: i,
                        value: scoreQ5,
                        onChanged: (value) {
                          setState(() {
                            onResponseTapped(5, i);
                          });
                        },
                      ),
                  ],
                ),
                getLabels(),
                const SizedBox(height: 30),
                Content(text: "Frage 6", context: context, color: Theme.of(context).colorScheme.tertiary),
                Text(textQ6, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Radio(
                        groupValue: i,
                        value: scoreQ6,
                        onChanged: (value) {
                          setState(() {
                            onResponseTapped(6, i);
                          });
                        },
                      ),
                  ],
                ),
                getLabels(),
                const SizedBox(height: 30),
                Content(text: "Frage 7", context: context, color: Theme.of(context).colorScheme.tertiary),
                Text(textQ7, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Radio(
                        groupValue: i,
                        value: scoreQ7,
                        onChanged: (value) {
                          setState(() {
                            onResponseTapped(7, i);
                          });
                        },
                      ),
                  ],
                ),
                getLabels(),
                const SizedBox(height: 30),
                Content(text: "Frage 8", context: context, color: Theme.of(context).colorScheme.tertiary),
                Text(textQ8, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Radio(
                        groupValue: i,
                        value: scoreQ8,
                        onChanged: (value) {
                          setState(() {
                            onResponseTapped(8, i);
                          });
                        },
                      ),
                  ],
                ),
                getLabels(),
                const SizedBox(height: 30),
                Content(text: "Frage 9", context: context, color: Theme.of(context).colorScheme.tertiary),
                Text(textQ9, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Radio(
                        groupValue: i,
                        value: scoreQ9,
                        onChanged: (value) {
                          setState(() {
                            onResponseTapped(9, i);
                          });
                        },
                      ),
                  ],
                ),
                getLabels(),
                const SizedBox(height: 30),
                Content(text: "Frage 10", context: context, color: Theme.of(context).colorScheme.tertiary),
                Text(textQ10, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Radio(
                        groupValue: i,
                        value: scoreQ10,
                        onChanged: (value) {
                          setState(() {
                            onResponseTapped(10, i);
                          });
                        },
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
