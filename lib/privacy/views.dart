import 'package:flutter/material.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/icon_item.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/privacy/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    privacyService = getIt<PrivacyPolicy>();
    privacyService.addListener(update);

    if (!privacyService.hasLoaded) {
      privacyService.loadPolicy();
    }
  }

  @override
  void dispose() {
    privacyService.removeListener(update);
    super.dispose();
  }

  /// A callback that is executed when the accept button was pressed.
  Future<void> onAcceptButtonPressed() async {
    if (privacyService.assetText == null) return;
    await privacyService.confirm(privacyService.assetText!);
  }

  @override
  Widget build(BuildContext context) {
    // Display loading indicator.
    if (!privacyService.hasLoaded) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: AnnotatedRegionWrapper(
          backgroundColor: Theme.of(context).colorScheme.background,
          brightness: Theme.of(context).brightness,
          child: const Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    // Display error text and retry button.
    if (privacyService.hasError) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: AnnotatedRegionWrapper(
          backgroundColor: Theme.of(context).colorScheme.background,
          brightness: Theme.of(context).brightness,
          child: SafeArea(
            child: Pad(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BoldSubHeader(
                    context: context,
                    text: "Achtung",
                  ),
                  const SmallVSpace(),
                  Content(
                    context: context,
                    textAlign: TextAlign.center,
                    text:
                        "Die PrioBike-Services sind zur Zeit nicht erreichbar. Vergewissere Dich außerdem, dass eine Verbindung zum Internet besteht und versuche es erneut.",
                  ),
                  const VSpace(),
                  BigButtonPrimary(
                    label: "Erneut versuchen",
                    onPressed: () {
                      privacyService.loadPolicy();
                    },
                    boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if ((privacyService.isConfirmed == true) && (widget.child != null)) return widget.child!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: AnnotatedRegionWrapper(
        backgroundColor: Theme.of(context).colorScheme.background,
        brightness: Theme.of(context).brightness,
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
                      Markdown(
                        data: privacyService.assetText!,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                      ),
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
