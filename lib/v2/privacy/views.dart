


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:priobike/v2/common/debug.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Debug these views.
void main() => debug(const PrivacyProxyView(wrappedView: Text("Proxied View")));

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

/// A privacy policy that was fetched from the server.
class PrivacyPolicy {
  /// The text of the privacy policy.
  String text;

  /// An indicator if the privacy policy was confirmed by the user.
  bool isConfirmed;

  /// Load the privacy policy from the server and check if it was accepted.
  static Future<PrivacyPolicy> load() async {
    // Load the current privacy policy.
    // TODO: Load this from the server.
    final current = await Future<String>.delayed(
      const Duration(seconds: 2),
      () => "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.",
    );

    // Load the accepted privacy policy.
    final storage = await SharedPreferences.getInstance();
    final accepted = storage.getString("priobike.privacy.accepted-policy");

    return PrivacyPolicy(text: current, isConfirmed: accepted == current);
  }

  PrivacyPolicy({required this.text, required this.isConfirmed});
}

class PrivacyProxyViewState extends State<PrivacyProxyView> {
  @override 
  Widget build(BuildContext context) {
    return FutureBuilder<PrivacyPolicy>(
      future: PrivacyPolicy.load(),
      builder: (BuildContext context, AsyncSnapshot<PrivacyPolicy> snapshot) {
        if (!snapshot.hasData) {
          // Still loading
          return renderLoadingIndicator();
        }
        if (!snapshot.data!.isConfirmed) {
          // Privacy policy not accepted
          return renderPrivacyPolicy(snapshot.data!);
        }
        // Privacy policy accepted
        return widget.wrappedView;
      },
    );
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return Stack(alignment: Alignment.center, children: [
      Column(children: const [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text("Lade...", style: TextStyle(fontSize: 16)),
      ]),
    ]);
  }

  /// Render the privacy policy.
  Widget renderPrivacyPolicy(PrivacyPolicy policy) {
    return Stack(alignment: Alignment.bottomCenter, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32), 
        child: ShaderMask(
          shaderCallback: (Rect rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.purple, Colors.transparent, Colors.transparent, Colors.purple],
              stops: [0.0, 0.1, 0.7, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstOut, 
          child: ListView(children: [
            const SizedBox(height: 64),

            const Text(
              "Diese App funktioniert mit", 
              style: TextStyle(fontSize: 38, fontWeight: FontWeight.w600)
            ),
            const Text(
              "deinen Daten.", 
              style: TextStyle(fontSize: 38, color: Colors.blueAccent, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            const Text(
              "Bitte lies dir deshalb kurz durch, wie wir deine Daten schützen. Das Wichtigste zuerst:", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300)
            ),
            const SizedBox(height: 32),

            Row(children: const [
              SizedBox(
                width: 64,
                height: 64,
                child: Icon(
                  Icons.route,
                  color: Colors.blueAccent,
                  size: 64,
                  semanticLabel: "Position",
                )
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Wir speichern deine Positionsdaten, aber nur anonymisiert und ohne deinen Start- und Zielort.", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300)
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: const [
              SizedBox(
                width: 64,
                height: 64,
                child: Icon(
                  Icons.lock,
                  color: Colors.blueAccent,
                  size: 64,
                  semanticLabel: "Position",
                )
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Wenn du die App personalisierst, indem du zum Beispiel einen Shortcut nach Hause erstellst, wird dies nur auf diesem Gerät gespeichert.", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300)
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: const [
              SizedBox(
                width: 64,
                height: 64,
                child: Icon(
                  Icons.lightbulb,
                  color: Colors.blueAccent,
                  size: 64,
                  semanticLabel: "Position",
                )
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Um die App zu verbessern, sammeln wir Informationen über den Komfort von Straßen, Fehlerberichte und Feedback.", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300)
                ),
              ),
            ]),
            const SizedBox(height: 32),

            const Divider(thickness: 1),

            const SizedBox(height: 32),
            Text(policy.text),
            const SizedBox(height: 256),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(32), 
        child: RawMaterialButton(
          fillColor: Colors.blueAccent,
          splashColor: Colors.lightBlue,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const <Widget>[
                SizedBox(width: 16),
                Icon(
                  Icons.check,
                  color: Colors.white,
                ),
                SizedBox(width: 16),
                Text(
                  "Akzeptieren",
                  maxLines: 1,
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.normal),
                ),
                SizedBox(width: 16),
              ],
            ),
          ),
          onPressed: () {},
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
        ),
      ),
    ]);
}
}
