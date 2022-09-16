import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/privacy/services.dart';
import 'package:provider/provider.dart';

/// A list item with icon.
class IconItem extends Row {
  IconItem({Key? key, required IconData icon, required String text, required BuildContext context}) : super(
    key: key,
    children: [
      SizedBox(
        width: 64,
        height: 64,
        child: Icon(
          icon,
          color: Colors.blueAccent,
          size: 64,
          semanticLabel: text,
        )
      ),
      const SmallHSpace(),
      Expanded(child: Content(text: text, context: context)),
    ]
  );
}

/// A view that displays the privacy policy.
class PrivacyPolicyView extends StatefulWidget {
  final Widget? child;

  /// Create the privacy proxy view with the wrapped view.
  const PrivacyPolicyView({this.child, Key? key}) : super(key: key);

  @override 
  PrivacyPolicyViewState createState() => PrivacyPolicyViewState();
}

class PrivacyPolicyViewState extends State<PrivacyPolicyView> {
  /// The associated privacy service, which is injected by the provider.
  late PrivacyPolicy s;

  @override
  void didChangeDependencies() {
    s = Provider.of<PrivacyPolicy>(context);

    // Load once the window was built.
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await s.loadPolicy(context);
    });

    super.didChangeDependencies();
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return Scaffold(body: 
      Container(
        color: Theme.of(context).colorScheme.background,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Lade...", style: TextStyle(fontSize: 16)),
          ]
        ),
      ),
    );
  }

  /// A callback that is executed when the accept button was pressed.
  Future<void> onAcceptButtonPressed() async {
    await s.confirm();
  }

  @override 
  Widget build(BuildContext context) {
    if (!s.hasLoaded) return Container();

    if (s.isConfirmed == true && widget.child != null) return widget.child!;

    return Scaffold(body: 
      Container(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          alignment: Alignment.bottomCenter, 
          children: [
            HPad(child: 
              Fade(child: 
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      const SizedBox(height: 164),
                      if (!s.hasChanged!) 
                        Header(text: "Diese App funktioniert mit", context: context),
                      if (!s.hasChanged!) 
                        Header(text: "deinen Daten.", color: Colors.blueAccent, context: context),
                      if (s.hasChanged!) 
                        Header(text: "Wir haben die Erklärung zum", context: context),
                      if (s.hasChanged!) 
                        Header(text: "Datenschutz aktualisiert.", color: Colors.blueAccent, context: context),
                      const SmallVSpace(),
                      if (!s.hasChanged!) 
                        SubHeader(text: "Bitte lies dir deshalb kurz durch, wie wir deine Daten schützen. Das Wichtigste zuerst:", context: context),
                      if (s.hasChanged!) 
                        SubHeader(text: "Lies dir hierzu kurz unsere Änderungen durch.", context: context),
                      const VSpace(),
                      IconItem(icon: Icons.route, text: "Wir speichern deine Positionsdaten, aber nur anonymisiert und ohne deinen Start- und Zielort.", context: context),
                      const SmallVSpace(),
                      IconItem(icon: Icons.lock, text: "Wenn du die App personalisierst, indem du zum Beispiel einen Shortcut nach Hause erstellst, wird dies nur auf diesem Gerät gespeichert.", context: context),
                      const SmallVSpace(),
                      IconItem(icon: Icons.lightbulb, text: "Um die App zu verbessern, sammeln wir Informationen über den Komfort von Straßen, Fehlerberichte und Feedback.", context: context),
                      const VSpace(),
                      Content(text: s.text!, context: context),
                      const SizedBox(height: 256),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.child == null) Column(children: [
              const SizedBox(height: 64),
              Row(children: [
                AppBackButton(onPressed: () => Navigator.pop(context), icon: Icons.chevron_left),
              ]),
            ]),
            if (widget.child != null) Pad(
              child: BigButton(
                icon: Icons.check,
                iconColor: Colors.white,
                label: "Akzeptieren", 
                onPressed: onAcceptButtonPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
