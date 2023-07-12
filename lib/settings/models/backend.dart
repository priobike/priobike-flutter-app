import 'package:latlong2/latlong.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/routing/models/waypoint.dart';

enum Backend {
  production,
  staging,
}

extension BackendPath on Backend {
  String get path {
    switch (this) {
      case Backend.production:
        return "priobike.vkw.tu-dresden.de/production";
      case Backend.staging:
        return "priobike.vkw.tu-dresden.de/staging";
    }
  }
}

extension BackendName on Backend {
  String get name {
    switch (this) {
      case Backend.production:
        return "production";
      case Backend.staging:
        return "staging";
    }
  }
}

extension BackendPredictionServiceMqtt on Backend {
  String get predictionServiceMQTTPath {
    switch (this) {
      case Backend.production:
        return "priobike.vkw.tu-dresden.de";
      case Backend.staging:
        return "priobike.vkw.tu-dresden.de";
    }
  }

  int get predictionServiceMQTTPort {
    switch (this) {
      case Backend.production:
        return 20050;
      case Backend.staging:
        return 20032;
    }
  }

  String get predictionServiceMQTTUsername {
    switch (this) {
      case Backend.production:
        return "user";
      case Backend.staging:
        return "user";
    }
  }

  String get predictionServiceMQTTPassword {
    switch (this) {
      case Backend.production:
        return "mqtt@priobike-2022";
      case Backend.staging:
        return "mqtt@priobike-2022";
    }
  }
}

extension BackendPredictorMqtt on Backend {
  String get predictorMQTTPath {
    switch (this) {
      case Backend.production:
        return "priobike.vkw.tu-dresden.de";
      case Backend.staging:
        return "priobike.vkw.tu-dresden.de";
    }
  }

  int get predictorMQTTPort {
    switch (this) {
      case Backend.production:
        return 20054;
      case Backend.staging:
        return 20035;
    }
  }

  String get predictorMQTTUsername {
    switch (this) {
      case Backend.production:
        return "user";
      case Backend.staging:
        return "user";
    }
  }

  String get predictorMQTTPassword {
    switch (this) {
      case Backend.production:
        return "mqtt@priobike-2022";
      case Backend.staging:
        return "mqtt@priobike-2022";
    }
  }
}

extension BackendFROSTMqtt on Backend {
  String get frostMQTTPath {
    switch (this) {
      case Backend.production:
        return "tld.iot.hamburg.de";
      case Backend.staging:
        return "priobike.vkw.tu-dresden.de";
    }
  }

  int get frostMQTTPort {
    switch (this) {
      case Backend.production:
        return 1883;
      case Backend.staging:
        return 20056;
    }
  }
}

extension BackendRegion on Backend {
  String get region {
    switch (this) {
      case Backend.production:
        return "Hamburg";
      case Backend.staging:
        return "Dresden";
    }
  }

  LatLng get center {
    switch (this) {
      case Backend.production:
        return LatLng(53.551086, 9.993682);
      case Backend.staging:
        return LatLng(51.050407, 13.737262);
    }
  }
}

extension BackendShortcuts on Backend {
  List<Shortcut> get defaultShortcuts {
    switch (this) {
      case Backend.production:
        return [
          ShortcutLocation(
            name: "Elbphilharmonie",
            waypoint: Waypoint(53.5415701077766, 9.984275605794686,
                address: "Elbphilharmonie Hamburg, Platz der Deutschen Einheit, Hamburg"),
          ),
          ShortcutRoute(
            name: "Edmund-S.-Allee Ost ➔ West",
            waypoints: [
              Waypoint(53.560863, 9.990909, address: "Theodor-Heuss-Platz, Hamburg"),
              Waypoint(53.564378, 9.978001, address: "Rentzelstraße 55, 20146 Hamburg"),
            ],
          ),
          ShortcutRoute(
            name: "Edmund-S.-Allee West ➔ Ost",
            waypoints: [
              Waypoint(53.564378, 9.978001, address: "Rentzelstraße 55, 20146 Hamburg"),
              Waypoint(53.560863, 9.990909, address: "Theodor-Heuss-Platz, Hamburg"),
            ],
          ),
          ShortcutRoute(
            name: "B4 Ost ➔ West",
            waypoints: [
              Waypoint(53.547722154285324, 10.004045134575035, address: "Burchardstraße 11, 20095 Hamburg"),
              Waypoint(53.549482, 9.978636, address: "Ludwig-Erhard-Straße 20, 20459 Hamburg"),
              Waypoint(53.550264133830126, 9.971739418506827, address: "Millerntorpl. 20, 20359 Hamburg"),
            ],
          ),
          ShortcutRoute(
            name: "B4 West ➔ Ost",
            waypoints: [
              Waypoint(53.54990402934412, 9.971606990198367, address: "St. Pauli, 20359 Hamburg"),
              Waypoint(53.547262160720436, 10.004240381440082, address: "Oberbaumbrücke 1, 20457 Hamburg"),
            ],
          ),
          ShortcutRoute(
            name: "Lombardsbrücke Ost ➔ West",
            waypoints: [
              Waypoint(53.5511715, 10.0062077, address: "Steintorwall, 20095 Hamburg"),
              Waypoint(53.5575131, 9.99471, address: "Lombardsbrücke, 20354 Hamburg"),
              Waypoint(53.5575762, 9.9828379, address: "Jungiusstraße 3, 20355 Hamburg"),
              Waypoint(53.55285, 9.976352, address: "Ring 1 13, 20355 Hamburg"),
            ],
          ),
          ShortcutRoute(
            name: "Lombardsbrücke West ➔ Ost",
            waypoints: [
              Waypoint(53.55285, 9.976352, address: "Ring 1 13, 20355 Hamburg"),
              Waypoint(53.5579687, 9.9859757, address: "Gorch-Fock-Wall, 20354 Hamburg"),
              Waypoint(53.551241482916915, 10.005804047062561, address: "Steintorwall, 20095 Hamburg"),
            ],
          ),
        ];
      case Backend.staging:
        return [
          ShortcutRoute(
            name: "Teststrecke POT",
            waypoints: [
              Waypoint(51.03148, 13.72757, address: "Wegpunkt 1"),
              Waypoint(51.031149, 13.728232, address: "Wegpunkt 2"),
              Waypoint(51.03065, 13.72923, address: "Wegpunkt 3"),
              Waypoint(51.030151, 13.730213, address: "Wegpunkt 4"),
              Waypoint(51.030218, 13.728206, address: "Wegpunkt 5"),
              Waypoint(51.030613, 13.727809, address: "Wegpunkt 6"),
              Waypoint(51.031083, 13.727337, address: "Wegpunkt 7"),
            ],
          ),
          ShortcutRoute(
            name: "Quer durch Dresden",
            waypoints: [
              Waypoint(51.038294, 13.703280, address: "Clara-Viebig-Straße 9"),
              Waypoint(50.979067, 13.882596, address: "Elberadweg Heidenau"),
            ],
          ),
        ];
    }
  }
}
