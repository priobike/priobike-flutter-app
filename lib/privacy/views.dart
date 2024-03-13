import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/icon_item.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/privacy/services.dart';
import 'dart:convert' show utf8;

import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

/// A view that displays the privacy policy.
class PrivacyPolicyView extends StatefulWidget {
  final Widget? child;

  /// Create the privacy proxy view with the wrapped view.
  const PrivacyPolicyView({this.child, super.key});

  @override
  PrivacyPolicyViewState createState() => PrivacyPolicyViewState();
}

class PrivacyPolicyViewState extends State<PrivacyPolicyView> {
  /// The associated privacy service, which is injected by the provider.
  late PrivacyPolicy privacyService;

  /// The associated privacy service, which is injected by the provider.
  late Settings settings;

  /// The displayed privacy policy text.
  String? privacyPolicy;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    loadPolicy();
    setState(() {});
  }

  /// Load the privacy policy.
  void loadPolicy() {
    // Load once the window was built.

    settings = getIt<Settings>();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        String? privacyText;

        final response = await http.get(Uri.parse("https://${settings.backend.path}/privacy-policy"));

        if (response.statusCode == 200) {
          privacyText = _getPrivacyTextFromResponse(utf8.decode(response.bodyBytes));
        }

        await privacyService.loadPolicy(privacyText);
        setState(() {
          privacyPolicy = privacyText;
        });
      },
    );
  }

  /// Returns the privacy text from the html response string.
  String _getPrivacyTextFromResponse(String response) {
    // Use everything behind opening body tag.
    response = response.split("<body>")[1];
    // Use everything before closing body tag.
    response = response.split("</body>")[0];

    // Replace closing p tags with newline.
    response = response.replaceAll("<p>", '\n');
    response = response.replaceAll("</ul>\n", '');
    // Replace opening h tags with newline.
    response = response.replaceAll(RegExp(r'\<h[0-9]\>'), '\n');
    // Remove br tags.
    response = response.replaceAll("<br />", '');

    // Remove all other html tags.
    response = response.replaceAll(RegExp(r'\<[a-zA-Z0-9]*\>'), '');
    response = response.replaceAll(RegExp(r'\<\/[a-zA-Z0-9]*\>'), '');

    return response;
  }

  @override
  void initState() {
    super.initState();

    privacyService = getIt<PrivacyPolicy>();
    privacyService.addListener(update);

    loadPolicy();
  }

  @override
  void dispose() {
    privacyService.removeListener(update);
    super.dispose();
  }

  /// A callback that is executed when the accept button was pressed.
  Future<void> onAcceptButtonPressed() async {
    if (privacyPolicy == null) return;
    await privacyService.confirm(privacyPolicy!);
  }

  @override
  Widget build(BuildContext context) {
    if (!privacyService.hasLoaded) return Container();

    if ((privacyService.isConfirmed == true) && (widget.child != null)) return widget.child!;

    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.background,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            HPad(
              child: Fade(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 164),
                      if (!privacyService.hasChanged!) Header(text: "Diese App funktioniert mit", context: context),
                      if (!privacyService.hasChanged!)
                        Header(text: "Deinen Daten.", color: CI.radkulturRed, context: context),
                      if (privacyService.hasChanged!) Header(text: "Wir haben die Erklärung zum", context: context),
                      if (privacyService.hasChanged!)
                        Header(text: "Datenschutz aktualisiert.", color: CI.radkulturRed, context: context),
                      const SmallVSpace(),
                      if (!privacyService.hasChanged!)
                        SubHeader(
                            text:
                                "Bitte lies Dir deshalb kurz durch, wie wir Deine Daten schützen. Das Wichtigste zuerst:",
                            context: context),
                      if (privacyService.hasChanged!)
                        SubHeader(text: "Lies Dir hierzu kurz unsere Änderungen durch.", context: context),
                      const VSpace(),
                      IconItem(
                          icon: Icons.route,
                          text:
                              "Wir speichern Deine Positionsdaten, aber nur anonymisiert und ohne Deinen Start- und Zielort.",
                          context: context),
                      const SmallVSpace(),
                      IconItem(
                          icon: Icons.lock,
                          text:
                              "Wenn Du die App personalisierst, indem Du zum Beispiel einen Shortcut nach Hause erstellst, wird dies nur auf diesem Gerät gespeichert.",
                          context: context),
                      const SmallVSpace(),
                      IconItem(
                          icon: Icons.lightbulb,
                          text:
                              "Um die App zu verbessern, sammeln wir Informationen über den Komfort von Straßen, Fehlerberichte und Feedback.",
                          context: context),
                      const VSpace(),
                      Content(text: privacyService.assetText!, context: context),
                      const SizedBox(height: 256),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.child == null)
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        AppBackButton(onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                  ],
                ),
              ),
            if (widget.child != null)
              Pad(
                child: BigButtonPrimary(
                  label: "Akzeptieren",
                  onPressed: onAcceptButtonPressed,
                  boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 40, minHeight: 36),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
