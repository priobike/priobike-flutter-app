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
                          "Mit dem Jahr 2024 endet die Förderung für das Forschungs- und Entwicklungsprojekt PrioBike-HH und damit auch die Bereitstellung der PrioBike-App. Konkret wird die App noch bis zum 10. Dezember 2024 zum Erproben in den App Stores verfügbar sein. Mit dem Stichtag 10. Dezember muss die App dann aber aus den App Stores entfernt werden. Auch bereits installierte Apps werden nicht mehr weiter funktionieren, da parallel auch die Hintergrunddienste abgeschaltet werden.",
                      textAlign: TextAlign.center,
                    ),
                    const SmallVSpace(),
                    Content(
                      context: context,
                      textAlign: TextAlign.center,
                      text:
                          "Wir bedanken uns an dieser Stelle nochmals ganz herzlich bei allen Testenden für die insgesamt über 10.000 geradelten Kilometer und die wertvollen Rückmeldungen zur App. Mit dem Ausprobieren habt ihr einen wichtigen Beitrag zur Forschung und Entwicklung der PrioBike-App geleistet.",
                    ),
                    const VSpace(),
                    Content(
                      context: context,
                      textAlign: TextAlign.center,
                      text: "Ihr könnt euch auf der folgenden Webseite über das PrioBike-HH Projekt informieren: ",
                    ),
                    const SmallVSpace(),
                    BigButtonPrimary(
                      label: "Projektwebseite",
                      onPressed: () {
                        launchUrl(
                            Uri.parse(
                                "https://www.hamburg.de/politik-und-verwaltung/behoerden/bvm/die-themen-der-behoerde/intelligente-verkehrssysteme/priobike-192572"),
                            mode: LaunchMode.externalApplication);
                      },
                      boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
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
