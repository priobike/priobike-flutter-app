import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SummaryPageState();
  }
}

class _SummaryPageState extends State<SummaryPage> {
  late AppService app;

  @override
  Widget build(BuildContext context) {
    app = Provider.of<AppService>(context);

    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Zusammenfassung:",
                style: TextStyle(fontSize: 20),
              ),
              // const SizedBox(height: 30),
              // const Text("- Distanz"),
              // const Text("- Überfahrene Ampeln"),
              // const Text("- etc."),
              // const SizedBox(height: 30),
              // const Text("Bewertung der Fahrt"),
              // const Text("- 1 bis 5 Sterne"),
              // const Text("- Kommentarfeld"),
              // const SizedBox(height: 30),
              const Spacer(),
              Text(
                  "Länge der Strecke: ${app.currentRoute?.distance.toStringAsFixed(0)}m"),
              Text("Meter nach oben: ${app.currentRoute?.ascend}"),
              Text("Meter nach unten: ${app.currentRoute?.descend}"),
              app.currentRoute != null
                  ? Text(
                      "Dauer: ${(app.currentRoute!.estimatedDuration / 1000 / 60).toStringAsFixed(1)} Min.")
                  : const Text(''),
              Text("SessionID: ${app.session?.sessionId}"),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text("Daten zur Analyse spenden")),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.done),
                  label: const Text('Fertig'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
