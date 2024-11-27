import 'package:flutter/material.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/privacy/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

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
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: AnnotatedRegionWrapper(
          bottomBackgroundColor: Theme.of(context).colorScheme.surface,
          colorMode: Theme.of(context).brightness,
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
      return AnnotatedRegionWrapper(
        bottomBackgroundColor: Theme.of(context).colorScheme.surface,
        colorMode: Theme.of(context).brightness,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Pad(
              child: Fade(
                child: ListView(
                  children: [
                    const VSpace(),
                    BoldSubHeader(
                      context: context,
                      text: "Achtung",
                      textAlign: TextAlign.center,
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
                    const VSpace(),
                    const VSpace(),
                    Content(
                      context: context,
                      text:
                          "Ab dem 10.12.2024 sind die PrioBike-Services und die App eingestellt. Leider hat sich kein Weiterbetrieb der App nach Projektende (31.12.2024) ergeben.",
                      textAlign: TextAlign.center,
                    ),
                    const SmallVSpace(),
                    Content(
                      context: context,
                      textAlign: TextAlign.center,
                      text:
                          "Wir bedanken uns bei allen, die die App ausprobiert und damit einen bedeutenden Beitrag zur Forschung und Entwicklung beigetragen haben. Über die letzten Jahre hatten wir eine geschlossene Testphase, eine offene Testphase und zuletzt die Veröffentlichung der App. Währenddessen konnten wir regelmäßig Fahrten verzeichnen und auf Feedback vertrauen.",
                    ),
                    const VSpace(),
                    BoldContent(
                      context: context,
                      textAlign: TextAlign.center,
                      text: "Vielen Dank und allzeit gute Fahrt!",
                    ),
                    const VSpace(),
                    Content(
                      context: context,
                      textAlign: TextAlign.center,
                      text: "Für weitere Informationen zum Projekt könnt ihr euch an folgende E-Mail Adresse wenden:",
                    ),
                    const SmallVSpace(),
                    BigButtonPrimary(
                      label: "priobike@tu-dresden.de",
                      onPressed: () {
                        launchUrl(Uri.parse("mailto:priobike@tu-dresden.de"), mode: LaunchMode.externalApplication);
                      },
                      boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
                    ),
                    const VSpace(),
                    Content(
                      context: context,
                      textAlign: TextAlign.center,
                      text:
                          "Für die Technikbegeisterten: Auf unserer Github Seite könnt ihr den Großteil des PrioBike-Codes einsehen. Im Laufe des Jahres haben wir diesen veröffentlicht: ",
                    ),
                    const SmallVSpace(),
                    BigButtonPrimary(
                      label: "github.com/priobike",
                      onPressed: () {
                        launchUrl(Uri.parse("https://github.com/priobike"), mode: LaunchMode.externalApplication);
                      },
                      boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
                    ),
                    const VSpace(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if ((privacyService.isConfirmed == true) && (widget.child != null)) return widget.child!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: AnnotatedRegionWrapper(
        bottomBackgroundColor: Theme.of(context).colorScheme.surface,
        colorMode: Theme.of(context).brightness,
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
                      if (!privacyService.hasChanged!) ...[
                        Header(text: "Diese App funktioniert mit", context: context),
                        Header(text: "Deinen Daten.", color: CI.radkulturRed, context: context),
                        const SmallVSpace(),
                        SubHeader(
                            text: "Bitte lies Dir deshalb kurz durch, wie wir Deine Daten schützen.", context: context),
                      ],
                      if (privacyService.hasChanged!) ...[
                        Header(text: "Wir haben die Erklärung zum", context: context),
                        Header(text: "Datenschutz aktualisiert.", color: CI.radkulturRed, context: context),
                        const SmallVSpace(),
                        SubHeader(text: "Lies Dir hierzu kurz unsere Änderungen durch.", context: context),
                      ],
                      const VSpace(),
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
