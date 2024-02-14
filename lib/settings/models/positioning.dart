enum PositioningMode {
  gnss,
  follow18kmh,
  follow40kmh,
  sensor,
  recordedDresden,
  recordedHamburg,
  hamburgStatic1,
  dresdenStatic1,
  dresdenStatic2,
}

extension PositioningDescription on PositioningMode {
  String get description {
    switch (this) {
      case PositioningMode.gnss:
        return "GPS";
      case PositioningMode.follow18kmh:
        return "Route mit 18 km/h folgen";
      case PositioningMode.follow40kmh:
        return "Route mit 40 km/h folgen";
      case PositioningMode.sensor:
        return "Speed Sensor Daten";
      case PositioningMode.recordedDresden:
        return "Aufgezeichnet (Dresden, Teststrecke POT)";
      case PositioningMode.recordedHamburg:
        return "Aufgezeichnet (Hamburg, TS2 West -> Ost)";
      case PositioningMode.hamburgStatic1:
        return "Statisch (Hamburg, Hauptbahnhof)";
      case PositioningMode.dresdenStatic1:
        return "Statisch (Dresden, POT vor Ampel 1)";
      case PositioningMode.dresdenStatic2:
        return "Statisch (Dresden, POT vor Ampel 2)";
    }
  }
}
