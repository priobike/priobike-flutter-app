import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/feedback/messages/audio_answer.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/user.dart';

/// A view with 5 stars to rate the current ride.
class AudioRatingView extends StatefulWidget {
  const AudioRatingView({super.key});

  @override
  AudioRatingViewState createState() => AudioRatingViewState();
}

class AudioRatingViewState extends State<AudioRatingView> {
  final log = Logger("AudioRatingView");

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

  final listViewController = ScrollController();

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

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
  }

  /// Send an answered audio question.
  Future<bool> sendAudioFeedback() async {
    final susAnswers = [
      scoreQ1,
      scoreQ2,
      scoreQ3,
      scoreQ4,
      scoreQ5,
      scoreQ6,
      scoreQ7,
      scoreQ8,
      scoreQ9,
      scoreQ10,
    ];
    final comment = _textController.text;
    final sessionId = getIt<Ride>().sessionId ?? "";
    final userId = await User.getOrCreateId();
    final trackId = getIt<Tracking>().track?.sessionId ?? "";

    // Send all of the answered audioQuestions to the backend.
    final settings = getIt<Settings>();
    final baseUrl = settings.backend.path;
    final endpoint = Uri.parse('https://$baseUrl/audio-evaluation-service/answers/send-answer');

    final request = PostAudioAnswerRequest(
        userId: userId,
        sessionId: sessionId,
        trackId: trackId,
        susAnswers: susAnswers,
        comment: comment,
        debug: kDebugMode,
        // TODO implement how to detect driving with screen off.
        driveWithoutScreen: false);

    try {
      final response =
          await Http.post(endpoint, body: jsonEncode(request.toJson())).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        log.e("Error sending audio feedback to $endpoint: ${response.body}");
      } else {
        log.i("Sent audio feedback to $endpoint");
      }
    } catch (error) {
      final hint = "Error sending audio feedback to $endpoint: $error";
      log.e(hint);
    }
    return true;
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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20.0, top: 20.0, right: 20.0, bottom: 0),
        child: Column(
          children: [
            const SizedBox(height: 26),
            Row(
              children: [
                const Spacer(),
                IconButton(
                  onPressed: () {
                    sendAudioFeedback();
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.close,
                    size: 50,
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                controller: listViewController,
                children: [
                  const SizedBox(height: 160),
                  Text(
                    'Dein Feedback zur Sprachausgabe',
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Liebe Nutzerin, lieber Nutzer,\n\nvielen Dank für das Testen der Sprachausgabe, die ich im Rahmen einer Studienarbeit entwickelt habe. Ich würde mich über eine Bewertung der Funktionalität freuen. Dein Feedback wird für die Auswertung des Navigationsansatzes benötigt und hilft dabei, die Sprachausgabe zu verbessern.\n\nVielen Dank!",
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Divider(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1)),
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
                  Divider(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1)),
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
                  Divider(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1)),
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
                  Divider(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1)),
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
                  Divider(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1)),
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
                  Divider(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1)),
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
                  Divider(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1)),
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
                  Divider(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1)),
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
                  Divider(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1)),
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
                  Divider(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1)),
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
                  Divider(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1)),
                  const SizedBox(height: 15),
                  Content(text: "Anmerkungen:", context: context, color: Theme.of(context).colorScheme.tertiary),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _textController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(24),
                        ),
                      ),
                      hintText: "Hier ist Platz für Anmerkungen und Kommentare",
                      hintStyle: TextStyle(fontSize: 15),
                    ),
                    // Leave this at a really high value to make sure the button is also displayed.
                    scrollPadding: const EdgeInsets.only(bottom: 300),
                  ),
                  const SizedBox(height: 30),
                  BigButtonPrimary(
                    label: "Danke!",
                    onPressed: () {
                      sendAudioFeedback();
                      Navigator.pop(context);
                    },
                    boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
                  ),
                  const VSpace(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
