import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:url_launcher/url_launcher.dart';

class SurveyView extends StatefulWidget {
  final bool dismissible;

  final BorderRadius? borderRadius;

  const SurveyView({super.key, required this.dismissible, this.borderRadius});

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
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tile(
      borderRadius: widget.borderRadius ??
          const BorderRadius.all(
            Radius.circular(24),
          ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      fill: Theme.of(context).colorScheme.surfaceVariant,
      onPressed: () {
        _launchSurvey();
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
                  BoldContent(text: "Hast Du kurz Zeit?", context: context, textAlign: TextAlign.left),
                  const SmallVSpace(),
                  Small(
                    text: "Wir würden uns freuen, wenn Du an unserer Umfrage teilnimmst.",
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.75),
                    context: context,
                  ),
                ],
              ),
            ),
            if (widget.dismissible) const SizedBox(width: 8),
            if (widget.dismissible)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  settings.setDismissedSurvey(true);
                },
              ),
          ]),
          const SmallVSpace(),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Small(
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
    );
  }
}
