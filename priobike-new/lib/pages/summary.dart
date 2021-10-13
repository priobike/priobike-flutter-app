import 'package:flutter/material.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SummaryPageState();
  }
}

class _SummaryPageState extends State<SummaryPage> {
  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 30),
              const Text("- Distanz"),
              const Text("- Überfahrene Ampeln"),
              const Text("- etc."),
              const SizedBox(height: 30),
              const Text("Bewertung der Fahrt"),
              const Text("- 1 bis 5 Sterne"),
              const Text("- Kommentarfeld"),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text("Daten zur Analyse spenden")),
              const Spacer(),
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
