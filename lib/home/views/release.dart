import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/services/features.dart';
import 'package:url_launcher/url_launcher.dart';

class ReleaseInfoView extends StatefulWidget {
  const ReleaseInfoView({super.key});

  @override
  ReleaseInfoViewState createState() => ReleaseInfoViewState();
}

class ReleaseInfoViewState extends State<ReleaseInfoView> {
  late Feature feature;

  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    feature = getIt<Feature>();
  }

  /// Open a text view explaining how to switch to the official app store.
  void openExplanation() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReleaseInfoExplanation()));
  }

  @override
  Widget build(BuildContext context) {
    if (feature.isRelease) {
      return Container();
    }

    var store = "";
    if (Platform.isAndroid) {
      store = "Google Play Store";
    } else if (Platform.isIOS) {
      store = "App Store";
    }

    return BlendIn(
      child: Container(
        padding: const EdgeInsets.fromLTRB(40, 24, 24, 0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Small(
                text:
                    "Du verwendest aktuell noch eine Testversion der App. Wechsle jetzt zur offiziellen Version aus dem $store.",
                context: context,
              ),
            ),
            const HSpace(),
            SmallIconButtonTertiary(icon: Icons.chevron_right_rounded, onPressed: openExplanation)
          ],
        ),
      ),
    );
  }
}

const iosExplanation = """
## iOS

Um das Beta-Programm für iOS zu verlassen, musst du das TestFlight-Programm verlassen und die App aus dem App Store installieren. Wir empfehlen dir, die App vorher nicht manuell zu löschen, da sonst deine gespeicherte Routen verloren gehen. Mit einer Installation aus dem App Store überschreibst du die TestFlight-Version und behältst deine Daten.
""";

const androidExplanation = """
## Android

Um das Beta-Programm für Android zu verlassen, musst du erneut auf den Einladungslink und dann auf "Verlassen" klicken. Anschließend kannst du die App aus dem Google Play Store installieren. Danach solltest du in der Lage sein, deine App zu aktualisieren und verlierst somit nicht deine gespeicherten Routen.

Einladungslink: https://play.google.com/apps/testing/de.tudresden.priobike

Für interne Tester: Zunächst die Entwickleroptionen im Play Store aktivieren, um interner Tester zu werden. Dazu klickst du 7 Mal auf die Play Store-Version. Gehe anschließend zu Einstellungen -> Allgemein -> Entwickleroptionen und aktiviere die interne App-Bereitstellung. Nachdem du den Einladungslink akzeptiert hast, kann die interne Version aktualisiert werden.
""";

String explanationTemplate(e1, e2) => """
## Wechsel zur offiziellen Version

Du verwendest aktuell noch eine Testversion der App. Die offizielle Version kannst du dir nun in ein paar Schritten installieren.

$e1

$e2

## Unterstützung

Bei Fragen oder Problemen wende dich bitte an unseren Support: priobike@tu-dresden.de
""";

class ReleaseInfoExplanation extends StatelessWidget {
  const ReleaseInfoExplanation({super.key});

  @override
  Widget build(BuildContext context) {
    final explanation = Platform.isIOS
        ? explanationTemplate(iosExplanation, androidExplanation)
        : explanationTemplate(androidExplanation, iosExplanation);

    var styleSheet = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      h2: Theme.of(context).textTheme.headlineLarge!.copyWith(color: CI.radkulturRed),
      // Don't highlight links
      a: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: CI.radkulturRed,
            fontWeight: FontWeight.w700,
          ),
    );

    return AnnotatedRegionWrapper(
      bottomBackgroundColor: Theme.of(context).colorScheme.surface,
      colorMode: Theme.of(context).brightness,
      child: Scaffold(
        body: Fade(
          child: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Row(
                        children: [
                          AppBackButton(onPressed: () => Navigator.pop(context)),
                          const HSpace(),
                          SubHeader(text: "Neuigkeiten", context: context),
                        ],
                      ),
                    ],
                  ),
                  const SmallVSpace(),
                  Markdown(
                    data: explanation,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    styleSheet: styleSheet,
                    onTapLink: (text, href, title) {
                      if (href == null) return;
                      final uri = Uri.parse(href);
                      launchUrl(uri);
                    },
                  ),
                  const SizedBox(height: 256),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
