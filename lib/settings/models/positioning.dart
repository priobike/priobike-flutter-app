enum Positioning {
  gnss,
  follow,
  recordedDresden,
  recordedHamburg,
}

extension PositioningDescription on Positioning {
  String get description {
    switch (this) {
      case Positioning.gnss: return "GPS";
      case Positioning.follow: return "Route mit 18 km/h folgen";
      case Positioning.recordedDresden: return "Aufgezeichnet (Dresden, Teststrecke POT)";
      case Positioning.recordedHamburg: return "Aufgezeichnet (Hamburg, TS2 West -> Ost)";
    }
  }
}
