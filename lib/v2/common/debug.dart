import 'package:flutter/material.dart';

/// Debug a view, by showing it in the simulator.
void debug(Widget view) {
  runApp(MaterialApp(
    title: 'Debug Container',
    theme: ThemeData(
      colorSchemeSeed: Colors.white,
      useMaterial3: true,
    ),
    home: Scaffold(
      body: view,
    ),
  ));
}
