import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:priobike/models/recommendation.dart';

import '../utils/routes.dart';

class MinimalDebugCyclingView extends StatelessWidget {
  MinimalDebugCyclingView(this.recommendation);

  final Recommendation recommendation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recommendation.toJson(),
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
