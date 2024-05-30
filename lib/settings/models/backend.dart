import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/routing/models/waypoint.dart';

/// The Backend enum which contains three types.
/// Production used for beta testing.
/// Staging used for testing in Dresden.
/// Release used for the Release-Version of the app.
enum Backend {
  production,
  staging,
  release,
}

extension BackendPath on Backend {
  String get path {
    switch (this) {
      case Backend.production:
        return "priobike.vkw.tu-dresden.de/production";
      case Backend.staging:
        return "priobike.vkw.tu-dresden.de/staging";
      case Backend.release:
        return "priobike-release.inf.tu-dresden.de";
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
      case Backend.release:
        return "release";
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
      case Backend.release:
        return "priobike.flow-d.de";
    }
  }

  int get predictionServiceMQTTPort {
    switch (this) {
      case Backend.production:
        return 20050;
      case Backend.staging:
        return 20032;
      case Backend.release:
        return 20050;
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
      case Backend.release:
        return "priobike.flow-d.de";
    }
  }

  int get predictorMQTTPort {
    switch (this) {
      case Backend.production:
        return 20054;
      case Backend.staging:
        return 20035;
      case Backend.release:
        return 20054;
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
      case Backend.release:
        return "priobike.flow-d.de";
    }
  }

  int get frostMQTTPort {
    switch (this) {
      case Backend.production:
        return 1883;
      case Backend.staging:
        return 20056;
      case Backend.release:
        return 1883;
    }
  }
}

extension BackendRegion on Backend {
  String get region {
    switch (this) {
      case Backend.production:
        return "Hamburg (Beta)";
      case Backend.staging:
        return "Dresden";
      case Backend.release:
        return "Hamburg";
    }
  }

  String get regionName {
    switch (this) {
      case Backend.production:
        return "Hamburg";
      case Backend.staging:
        return "Dresden";
      case Backend.release:
        return "Hamburg";
    }
  }

  LatLng get center {
    switch (this) {
      case Backend.production:
        return const LatLng(53.551086, 9.993682);
      case Backend.staging:
        return const LatLng(51.050407, 13.737262);
      case Backend.release:
        return const LatLng(53.551086, 9.993682);
    }
  }

  Future<String> get boundaryGeoJson async {
    switch (this) {
      case Backend.production:
        return await rootBundle.loadString("assets/geo/hamburg-boundary.geojson");
      case Backend.staging:
        return await rootBundle.loadString("assets/geo/dresden-boundary.geojson");
      case Backend.release:
        return await rootBundle.loadString("assets/geo/hamburg-boundary.geojson");
    }
  }
}

extension BackendShortcuts on Backend {
  List<Shortcut> get defaultShortcuts {
    switch (this) {
      case Backend.production:
        return [
          ShortcutLocation(
            id: UniqueKey().toString(),
            name: "Elbphilharmonie",
            waypoint: Waypoint(53.5415701077766, 9.984275605794686,
                address: "Elbphilharmonie Hamburg, Platz der Deutschen Einheit, Hamburg"),
          ),
          ShortcutRoute(
            id: UniqueKey().toString(),
            name: "Altona ➔ City",
            waypoints: [
              Waypoint(53.5522524, 9.9313068, address: "Altona-Altstadt, 22767, Hamburg, Deutschland"),
              Waypoint(53.5536507, 9.9893664, address: "Jungfernstieg, Altstadt, 20095, Hamburg, Deutschland"),
            ],
          ),
        ];
      case Backend.staging:
        return [
          ShortcutRoute(
            id: UniqueKey().toString(),
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
            id: UniqueKey().toString(),
            name: "Quer durch Dresden",
            waypoints: [
              Waypoint(51.038294, 13.703280, address: "Clara-Viebig-Straße 9"),
              Waypoint(50.979067, 13.882596, address: "Elberadweg Heidenau"),
            ],
          ),
        ];
      case Backend.release:
        return [
          ShortcutLocation(
            id: UniqueKey().toString(),
            name: "Elbphilharmonie",
            waypoint: Waypoint(53.5415701077766, 9.984275605794686,
                address: "Elbphilharmonie Hamburg, Platz der Deutschen Einheit, Hamburg"),
          ),
          ShortcutRoute(
            id: UniqueKey().toString(),
            name: "Altona ➔ City",
            waypoints: [
              Waypoint(53.5522524, 9.9313068, address: "Altona-Altstadt, 22767, Hamburg, Deutschland"),
              Waypoint(53.5536507, 9.9893664, address: "Jungfernstieg, Altstadt, 20095, Hamburg, Deutschland"),
            ],
          ),
        ];
    }
  }
}

extension LiveTracking on Backend {
  String get liveTrackingMQTTPath {
    switch (this) {
      case Backend.production:
        return "j5g.vkw.tu-dresden.de";
      case Backend.staging:
        return "j5g.vkw.tu-dresden.de";
      case Backend.release:
        return "j5g.vkw.tu-dresden.de";
    }
  }

  int get liveTrackingMQTTPort {
    switch (this) {
      case Backend.production:
        return 20001;
      case Backend.staging:
        return 20001;
      case Backend.release:
        return 20001;
    }
  }
}

extension Simulator on Backend {
  String get simulatorMQTTPath {
    switch (this) {
      case Backend.production:
        return "priobike.vkw.tu-dresden.de";
      case Backend.staging:
        return "priobike.vkw.tu-dresden.de";
      case Backend.release:
        return "priobike.vkw.tu-dresden.de";
    }
  }

  int get simulatorMQTTPort {
    switch (this) {
      case Backend.production:
        return 20036;
      case Backend.staging:
        return 20036;
      case Backend.release:
        return 20036;
    }
  }
}
