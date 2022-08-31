import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/privacy/services.dart';
import 'package:provider/provider.dart';

/// A list item with icon.
class IconItem extends Row {
  IconItem({Key? key, required IconData icon, required String text}) : super(
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
      Expanded(child: Content(text: text)),
    ]
  );
}

/// A view that displays the privacy policy.
class PrivacyPolicyView extends StatefulWidget {
  final void Function(BuildContext ctx)? onConfirmed;

  /// Create the privacy proxy view with the wrapped view.
  const PrivacyPolicyView({this.onConfirmed, Key? key}) : super(key: key);

  @override 
  PrivacyPolicyViewState createState() => PrivacyPolicyViewState();
}

class PrivacyPolicyViewState extends State<PrivacyPolicyView> {
  /// The associated privacy service, which is injected by the provider.
  late PrivacyPolicyService s;

  @override
  void didChangeDependencies() {
    s = Provider.of<PrivacyPolicyService>(context);

    // Load once the window was built.
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await s.loadPolicy(context, () => widget.onConfirmed?.call(context));
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
    widget.onConfirmed?.call(context);
  }

  @override 
  Widget build(BuildContext context) {
    if (!s.hasLoaded) return renderLoadingIndicator();

    return Scaffold(body: 
      Container(
        color: Theme.of(context).colorScheme.background,
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
                      if (!s.hasChanged! || widget.onConfirmed == null) 
                        Header(text: "Diese App funktioniert mit"),
                      if (!s.hasChanged! || widget.onConfirmed == null) 
                        Header(text: "deinen Daten.", color: Colors.blueAccent),
                      if (s.hasChanged! && widget.onConfirmed != null) 
                        Header(text: "Wir haben die Erklärung zum"),
                      if (s.hasChanged! && widget.onConfirmed != null) 
                        Header(text: "Datenschutz aktualisiert.", color: Colors.blueAccent),
                      const SmallVSpace(),
                      if (!s.hasChanged!) 
                        SubHeader(text: "Bitte lies dir deshalb kurz durch, wie wir deine Daten schützen. Das Wichtigste zuerst:"),
                      if (s.hasChanged! && widget.onConfirmed != null) 
                        SubHeader(text: "Lies dir hierzu kurz unsere Änderungen durch."),
                      const VSpace(),
                      IconItem(icon: Icons.route, text: "Wir speichern deine Positionsdaten, aber nur anonymisiert und ohne deinen Start- und Zielort."),
                      const SmallVSpace(),
                      IconItem(icon: Icons.lock, text: "Wenn du die App personalisierst, indem du zum Beispiel einen Shortcut nach Hause erstellst, wird dies nur auf diesem Gerät gespeichert."),
                      const SmallVSpace(),
                      IconItem(icon: Icons.lightbulb, text: "Um die App zu verbessern, sammeln wir Informationen über den Komfort von Straßen, Fehlerberichte und Feedback."),
                      const VSpace(),
                      Content(text: s.text!),
                      const SizedBox(height: 256),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.onConfirmed == null) Column(children: [
              const SizedBox(height: 64),
              Row(children: [
                AppBackButton(icon: Icons.chevron_left, onPressed: () => Navigator.pop(context)),
              ]),
            ]),
            if (widget.onConfirmed != null) Pad(
              child: BigButton(
                icon: Icons.check, 
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
