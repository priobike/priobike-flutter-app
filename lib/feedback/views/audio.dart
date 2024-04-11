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
  String textQ1 = "Ich denke, dass ich die Sprachausgabe häufig benutzen möchte.";
  String textQ2 = "Ich fand die Sprachausgabe zu komplex.";
  String textQ3 = "Ich fand die Sprachausgabe einfach zu benutzen.";
  String textQ4 = "Ich denke, ich bräuchte die Hilfe einer technisch versierten Person, "
                  "um die Sprachausgabe zu benutzen.";
  String textQ5 = "Ich fand die unterschiedlichen Funktionen der Sprachausgabe gut integriert.";
  String textQ6 = "Ich finde, dass es in der Sprachausgabe zu viele Inkonsistenzen gibt";
  String textQ7 = "Ich könnte mir vorstellen, dass die meisten Leute sehr schnell lernen, "
                  "die Sprachausgabe zu benutzen.";
  String textQ8 = "Ich fand die Sprachausgabe sehr umständlich zu bedienen.";
  String textQ9 = "Ich fühlte mich sehr sicher im Umgang mit der Sprachausgabe.";
  String textQ10 = "Ich musste eine Menge Dinge lernen, bevor ich mit der Sprachausgabe arbeiten konnte";

  final TextEditingController _textController = TextEditingController();

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
        Small(
            text: "Gar nicht \nzutreffend",
            context: context,
            color: Theme.of(context).colorScheme.tertiary,
            textAlign: TextAlign.left),
        const Spacer(),
        Small(
            text: "Völlig \nzutreffend",
            context: context,
            color: Theme.of(context).colorScheme.tertiary,
            textAlign: TextAlign.right),
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
            return Column(
              children: [
                const Divider(),
                const SizedBox(height: 15),
                Text("Frage 1", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Content(
                    text: textQ1,
                    context: context,
                    color: Theme.of(context).colorScheme.tertiary,
                    textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Text("Frage 2", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Content(
                    text: textQ2,
                    context: context,
                    color: Theme.of(context).colorScheme.tertiary,
                    textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Text("Frage 3", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Content(
                    text: textQ3,
                    context: context,
                    color: Theme.of(context).colorScheme.tertiary,
                    textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Text("Frage 4", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Content(
                    text: textQ4,
                    context: context,
                    color: Theme.of(context).colorScheme.tertiary,
                    textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Text("Frage 5", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Content(
                    text: textQ5,
                    context: context,
                    color: Theme.of(context).colorScheme.tertiary,
                    textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Text("Frage 6", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Content(
                    text: textQ6,
                    context: context,
                    color: Theme.of(context).colorScheme.tertiary,
                    textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Text("Frage 7", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Content(
                    text: textQ7,
                    context: context,
                    color: Theme.of(context).colorScheme.tertiary,
                    textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Text("Frage 8", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Content(
                    text: textQ8,
                    context: context,
                    color: Theme.of(context).colorScheme.tertiary,
                    textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Text("Frage 9", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Content(
                    text: textQ9,
                    context: context,
                    color: Theme.of(context).colorScheme.tertiary,
                    textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Text("Frage 10", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Content(
                    text: textQ10,
                    context: context,
                    color: Theme.of(context).colorScheme.tertiary,
                    textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                getLabels(),
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Content(text: "Anmerkungen:", context: context, color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(height: 5),
                TextField(
                  controller: _textController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      hintText: "Hier ist Platz für Anmerkungen und Kommentare",
                      hintStyle: TextStyle(fontSize: 15)),
                ),
                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ],
    );
  }
}
