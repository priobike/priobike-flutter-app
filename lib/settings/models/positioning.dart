enum Positioning {
  gnss,
  follow18kmh,
  follow40kmh,
  recordedDresden,
  recordedHamburg,
  dresdenStatic1,
  dresdenStatic2,
}

extension PositioningDescription on Positioning {
  String get description {
    switch (this) {
      case Positioning.gnss: return "GPS";
      case Positioning.follow18kmh: return "Durchschnittlicher Radfahrer: Route mit 18 km/h folgen";
      case Positioning.follow40kmh: return "Sehr schneller Radfahrer: Route mit 40 km/h folgen";
      case Positioning.recordedDresden: return "Aufgezeichnet (Dresden, Teststrecke POT)";
      case Positioning.recordedHamburg: return "Aufgezeichnet (Hamburg, TS2 West -> Ost)";
      case Positioning.dresdenStatic1: return "Statisch (Dresden, POT vor Ampel 1)";
      case Positioning.dresdenStatic2: return "Statisch (Dresden, POT vor Ampel 2)";
    }
  }
}
