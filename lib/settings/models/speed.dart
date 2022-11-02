enum SpeedMode {
  max30kmh,
  max40kmh,
}

extension SpeedModeDescription on SpeedMode {
  String get description {
    switch (this) {
      case SpeedMode.max30kmh:
        return "Bis 30 km/h (Empfohlen)";
      case SpeedMode.max40kmh:
        return "Bis 40 km/h";
    }
  }
}

extension SpeedModeSpeed on SpeedMode {
  double get maxSpeed {
    switch (this) {
      case SpeedMode.max30kmh:
        return 30;
      case SpeedMode.max40kmh:
        return 40;
    }
  }
}
