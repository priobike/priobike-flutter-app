import 'package:flutter/material.dart';

enum BikeType {
  citybike,
  racingbike,
  mountainbike,
  cargobike,
}

extension BikeTypeRoutingProfile on BikeType {
  String get ghConfigName {
    switch (this) {
      case BikeType.citybike:
        return "bike2_default";
      case BikeType.mountainbike:
        return "mtb_default"; // FIXME: Change to mtb2_default when supported
      case BikeType.racingbike:
        return "racingbike_default"; // FIXME: Change to mtb2_default when supported
      case BikeType.cargobike:
        return "racingbike_default"; // FIXME: Change to mtb2_default when supported
    }
  }
}

extension BikeTypeDescription on BikeType {
  String description() {
    switch (this) {
      case BikeType.citybike:
        return "Stadtrad";
      case BikeType.racingbike:
        return "Rennrad";
      case BikeType.mountainbike:
        return "Mountainbike";
      case BikeType.cargobike:
        return "Lastenrad";
    }
  }

  String get explanation {
    switch (this) {
      case BikeType.citybike:
        return "Das beste Routing für normale Fahrräder.";
      case BikeType.mountainbike:
        return "Mit diesem Routing werden auch unbefestigte Wege berücksichtigt.";
      case BikeType.racingbike:
        return "Das Rennradrouting vermeidet unbefestigte Wege und Kopfsteinpflaster.";
      case BikeType.cargobike:
        return "Unbefestigte Abschnitte und Kopfsteinpflaster werden vermieden.";
    }
  }
}

extension BikeTypeIcon on BikeType {
  IconData? icon() {
    switch (this) {
      case BikeType.citybike:
        return null;
      case BikeType.racingbike:
        return null;
      case BikeType.mountainbike:
        return null;
      case BikeType.cargobike:
        return null;
    }
  }
}

extension BikeTypeIconAsSting on BikeType {
  String iconAsString() {
    switch (this) {
      case BikeType.citybike:
        return "assets/icons/fahrrad.png";
      case BikeType.racingbike:
        return "assets/icons/rennrad.png";
      case BikeType.mountainbike:
        return "assets/icons/mtb.png";
      case BikeType.cargobike:
        return "assets/icons/lastenrad.png";
    }
  }
}
