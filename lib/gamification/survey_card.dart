import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/on_tap_animation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Card to be displayed on the home view of the app, if the gamification evaluation phase
///  has finished and the results can be surveyed.
class GameSurveyCard extends StatelessWidget {
  /// Url of the survey.
  final Uri _url = Uri.parse('https://bildungsportal.sachsen.de/umfragen/limesurvey/index.php/171349?lang=de');

  GameSurveyCard({Key? key}) : super(key: key);

  Future<void> _launchSurvey() async {
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: OnTapAnimation(
        scaleFactor: 0.95,
        onPressed: _launchSurvey,
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              width: 1,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.07),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
                blurRadius: 2,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              stops: const [0, 0.5, 1],
              colors: [
                Color.alphaBlend(CI.radkulturRed.withOpacity(0.5), Colors.white),
                CI.radkulturRed.withOpacity(0.8),
                Color.alphaBlend(CI.radkulturRed.withOpacity(0.5), Colors.white),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BoldSubHeader(text: 'Beta-Features Umfrage', context: context),
                          Small(
                            text:
                                'Bitte hilf uns, die Einführung der Beta-Features zu bewerten, indem Du an dieser 10 Minütigen Umfrage teilnimmst.',
                            context: context,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.search, size: 32),
                  ],
                ),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  BoldSmall(
                    context: context,
                    text: "Zur Umfrage",
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  const Icon(
                    Icons.redo,
                    size: 12,
                  )
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
