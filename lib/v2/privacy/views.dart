import 'package:flutter/material.dart';
import 'package:priobike/v2/common/debug.dart';
import 'package:priobike/v2/common/layout/buttons.dart';
import 'package:priobike/v2/common/fx.dart';
import 'package:priobike/v2/common/layout/spacing.dart';
import 'package:priobike/v2/common/layout/text.dart';
import 'package:priobike/v2/privacy/models.dart';

/// Debug these views.
void main() => debug(const PrivacyProxyView(wrappedView: Text("Proxied View")));

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

/// A privacy proxy view that displays the following:
/// - A loading indicator, if something is loading
/// - The wrapped view, if the current privacy policy matches the accepted one
/// - The current privacy policy, if none was accepted or if it changed
class PrivacyProxyView extends StatefulWidget {
  /// The wrapped view.
  final Widget wrappedView;

  /// Create the privacy proxy view with the wrapped view.
  const PrivacyProxyView({Key? key, required this.wrappedView}) : super(key: key);

  @override 
  PrivacyProxyViewState createState() => PrivacyProxyViewState();
}

class PrivacyProxyViewState extends State<PrivacyProxyView> {
  @override 
  Widget build(BuildContext context) {
    return FutureBuilder<PrivacyPolicy>(
      future: PrivacyPolicy.load(context),
      builder: (BuildContext context, AsyncSnapshot<PrivacyPolicy> snapshot) {
        if (!snapshot.hasData) {
          // Still loading
          return renderLoadingIndicator();
        }

        var policy = snapshot.data!;
        if (!policy.isConfirmed) {
          // Privacy policy not accepted
          return renderPrivacyPolicy(policy);
        }
        // Privacy policy accepted
        return widget.wrappedView;
      },
    );
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return Center(child: SizedBox(
      height: 128, 
      width: 128, 
      child: Column(children: const [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text("Lade...", style: TextStyle(fontSize: 16)),
      ])
    ));
  }

  /// Render the privacy policy.
  Widget renderPrivacyPolicy(PrivacyPolicy policy) {
    return Stack(alignment: Alignment.bottomCenter, children: [
      HPad(child: Fade(child: ListView(children: [
        const SizedBox(height: 64),
        if (!policy.hasChanged) Header(text: "Diese App funktioniert mit"),
        if (!policy.hasChanged) Header(text: "deinen Daten.", color: Colors.blueAccent),
        if (policy.hasChanged) Header(text: "Wir haben die Erklärung zum"),
        if (policy.hasChanged) Header(text: "Datenschutz aktualisiert.", color: Colors.blueAccent),
        const SmallVSpace(),
        if (!policy.hasChanged) SubHeader(text: "Bitte lies dir deshalb kurz durch, wie wir deine Daten schützen. Das Wichtigste zuerst:"),
        if (policy.hasChanged) SubHeader(text: "Lies dir hierzu kurz unsere Änderungen durch."),
        const VSpace(),
        IconItem(icon: Icons.route, text: "Wir speichern deine Positionsdaten, aber nur anonymisiert und ohne deinen Start- und Zielort."),
        const SmallVSpace(),
        IconItem(icon: Icons.lock, text: "Wenn du die App personalisierst, indem du zum Beispiel einen Shortcut nach Hause erstellst, wird dies nur auf diesem Gerät gespeichert."),
        const SmallVSpace(),
        IconItem(icon: Icons.lightbulb, text: "Um die App zu verbessern, sammeln wir Informationen über den Komfort von Straßen, Fehlerberichte und Feedback."),
        const VSpace(),
        Content(text: policy.text),
        const SizedBox(height: 256),
      ]))),
      Pad(child: BigButton(icon: Icons.check, label: "Akzeptieren", onPressed: () {
        setState(() {
          policy.confirm();
        });
      })),
    ]);
  }
}
