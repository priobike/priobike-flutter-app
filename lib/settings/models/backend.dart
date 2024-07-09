import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/services/load.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/settings/services/features.dart';
import 'package:priobike/settings/services/settings.dart';

enum City {
  hamburg,
  dresden,
}

extension CityName on City {
  String get nameDE {
    switch (this) {
      case City.hamburg:
        return "Hamburg";
      case City.dresden:
        return "Dresden";
    }
  }
}

extension GeoInfo on City {
  LatLng get center {
    switch (this) {
      case City.hamburg:
        return const LatLng(53.551086, 9.993682);
      case City.dresden:
        return const LatLng(51.050407, 13.737262);
    }
  }

  Future<String> get boundaryGeoJson async {
    switch (this) {
      case City.hamburg:
        return await rootBundle.loadString("assets/geo/hamburg-boundary.geojson");
      case City.dresden:
        return await rootBundle.loadString("assets/geo/dresden-boundary.geojson");
    }
  }

  Map<String, double> get roughBoundingBox {
    switch (this) {
      case City.hamburg:
        return {
          "minLon": 9.65,
          "maxLon": 10.4,
          "minLat": 53.35,
          "maxLat": 53.75,
        };
      case City.dresden:
        return {
          "minLon": 13.5,
          "maxLon": 14.0,
          "minLat": 50.9,
          "maxLat": 51.2,
        };
    }
  }
}

extension BackendInfo on City {
  List<Backend> get availableBackends {
    switch (this) {
      case City.hamburg:
        return [Backend.production, Backend.release];
      case City.dresden:
        return [Backend.staging];
    }
  }

  Backend get defaultBackend {
    switch (this) {
      case City.hamburg:
        return Backend.release;
      case City.dresden:
        return Backend.staging;
    }
  }

  Backend? get fallbackBackend {
    switch (this) {
      case City.hamburg:
        return Backend.production;
      case City.dresden:
        return null;
    }
  }

  Backend selectedBackend(bool allowFallback) {
    switch (this) {
      case City.hamburg:
        // If the internal version is used, we always use the default/selected backend.
        if (getIt<Feature>().canEnableInternalFeatures) {
          // If a backend is selected that does not belong to this city or if none is selected, we use the default backend.
          if (!availableBackends.contains(getIt<Settings>().manuallySelectedBackend) ||
              getIt<Settings>().manuallySelectedBackend == null) {
            return getIt<Settings>().city.defaultBackend;
          }
          return getIt<Settings>().manuallySelectedBackend!;
        }

        // If the internal version is not used, we check if the load status recommends another backend.
        if (allowFallback && getIt<LoadStatus>().useFallback) {
          return Backend.production;
        }

        // Otherwise we use always release.
        return Backend.release;
      case City.dresden:
        return Backend.staging;
    }
  }
}

extension DefaultShortcuts on City {
  List<Shortcut> get defaultShortcuts {
    switch (this) {
      case City.hamburg:
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
            routeTimeText: "17 Min.",
            routeLengthText: "4.8 km",
          ),
        ];
      case City.dresden:
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
    }
  }
}

/// The Backend enum which contains three types.
/// Fallback HH (TUD).
/// Staging DD (TUD).
/// Release HH (flow-d).
/// Naming convention: [environment].[city]
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
