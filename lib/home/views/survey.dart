import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:url_launcher/url_launcher.dart';

class SurveyView extends StatefulWidget {
  const SurveyView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SurveyViewState();
}

class SurveyViewState extends State<SurveyView> {
  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// Url of the survey.
  final Uri _url = Uri.parse('https://bildungsportal.sachsen.de/umfragen/limesurvey/index.php/946427?lang=de');

  @override
  void initState() {
    super.initState();

    settings = getIt<Settings>();
  }

  Future<void> _launchSurvey() async {
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Tile(
        borderRadius: const BorderRadius.all(
          Radius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        fill: Theme.of(context).colorScheme.background,
        onPressed: () {
          _launchSurvey();
          settings.setDismissedSurvey(true);
        },
        content: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BoldContent(
                        text: "Vielen Dank für’s Ausprobieren der PrioBike-App. Klappt alles?",
                        context: context,
                        textAlign: TextAlign.left),
                    Small(
                      text:
                          "Wenn nicht — umso besser. Wir sind auf Dein Feedback gespannt. Bitte nimm Dir etwa 10 Minuten Zeit für unsere Umfrage",
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.75),
                      context: context,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  settings.setDismissedSurvey(true);
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
