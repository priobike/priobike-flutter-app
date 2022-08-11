

import 'package:flutter/material.dart';
import 'package:priobike/v2/home/models/shortcut.dart';
import 'package:priobike/v2/routing/models/waypoint.dart';

class ShortcutsService with ChangeNotifier {
  /// All available shortcuts.
  List<Shortcut>? shortcuts;

  ShortcutsService();

  /// Load the custom shortcuts.
  Future<void> loadShortcuts() async {
    if (shortcuts != null) return;
    // TODO: Make shortcuts non-static (configurable by the user).
    shortcuts = const [
      Shortcut(
        name: "Teststrecke 1 (Edmund-S.-Allee) Ost ➔ West",
        icon: Icons.route,
        waypoints: [
          Waypoint(53.560863, 9.990909, address: "Theodor-Heuss-Platz, Hamburg"),
          Waypoint(53.564378, 9.978001, address: "Rentzelstraße 55, 20146 Hamburg"),
        ]
      ),
      Shortcut(
        name: "Teststrecke 1 (Edmund-S.-Allee) West ➔ Ost",
        icon: Icons.route,
        waypoints: [
          Waypoint(53.564378, 9.978001, address: "Rentzelstraße 55, 20146 Hamburg"),
          Waypoint(53.560863, 9.990909, address: "Theodor-Heuss-Platz, Hamburg"),
        ]
      ),
      Shortcut(
        name: "Teststrecke 2 (B4) Ost ➔ West",
        icon: Icons.route,
        waypoints: [
          Waypoint(53.547722154285324, 10.004045134575035, address: "Burchardstraße 11, 20095 Hamburg"),
          Waypoint(53.549482, 9.978636, address: "Ludwig-Erhard-Straße 20, 20459 Hamburg"),
          Waypoint(53.550264133830126, 9.971739418506827, address: "Millerntorpl. 20, 20359 Hamburg"),
        ]
      ),
      Shortcut(
        name: "Teststrecke 2 (B4) West ➔ Ost",
        icon: Icons.route,
        waypoints: [
          Waypoint(53.54990402934412, 9.971606990198367, address: "St. Pauli, 20359 Hamburg"),
          Waypoint(53.547262160720436, 10.004240381440082, address: "Oberbaumbrücke 1, 20457 Hamburg"),
        ]
      ),
      Shortcut(
        name: "Teststrecke 3 (Lombardsbrücke) Ost ➔ West",
        icon: Icons.route,
        waypoints: [
          Waypoint(53.5511715, 10.0062077, address: "Steintorwall, 20095 Hamburg"),
          Waypoint(53.5575131, 9.99471, address: "Lombardsbrücke, 20354 Hamburg"),
          Waypoint(53.5575762, 9.9828379, address: "Jungiusstraße 3, 20355 Hamburg"),
          Waypoint(53.55285, 9.976352, address: "Ring 1 13, 20355 Hamburg"),
        ]
      ),
      Shortcut(
        name: "Teststrecke 3 (Lombardsbrücke) West ➔ Ost",
        icon: Icons.route,
        waypoints: [
          Waypoint(53.55285, 9.976352, address: "Ring 1 13, 20355 Hamburg"),
          Waypoint(53.5579687, 9.9859757, address: "Gorch-Fock-Wall, 20354 Hamburg"),
          Waypoint(53.551241482916915, 10.005804047062561, address: "Steintorwall, 20095 Hamburg"),
        ]
      ),
    ];
    notifyListeners();
  }
}
