import 'package:flutter/material.dart';
import 'package:priobike/services/app.dart';
import 'package:provider/provider.dart';

import '../utils/routes.dart';

class MinimalDebugCyclingView extends StatefulWidget {
  const MinimalDebugCyclingView({Key? key}) : super(key: key);

  @override
  State<MinimalDebugCyclingView> createState() =>
      _MinimalDebugCyclingViewState();
}

class _MinimalDebugCyclingViewState extends State<MinimalDebugCyclingView> {
  late AppService app;

  @override
  Widget build(BuildContext context) {
    app = Provider.of<AppService>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app.currentRecommendation!.toJson(),
              style: const TextStyle(fontSize: 20),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.stop),
                label: const Text('Fahrt beenden'),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, Routes.summary);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
