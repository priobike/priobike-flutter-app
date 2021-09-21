import 'package:flutter/material.dart';
import 'package:priobike/utils/routes.dart';

class CyclingPage extends StatefulWidget {
  const CyclingPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CyclingPageState();
  }
}

class _CyclingPageState extends State<CyclingPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(children: [
            const Text("Jetzt wird gerade gefahren"),
            ElevatedButton(
              child: const Text('Fahrt beenden'),
              onPressed: () {
                Navigator.pushReplacementNamed(context, Routes.summary);
              },
            ),
          ]),
        ),
      ),
    );
  }
}
