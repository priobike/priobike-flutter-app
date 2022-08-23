enum RideViewsMode {
  onlySpeedometerView,
  displayAlternativeRideViews,
}

extension RideViewsModeDescription on RideViewsMode {
  String get description {
    switch (this) {
      case RideViewsMode.onlySpeedometerView: return "Nur Tacho-Ansicht";
      case RideViewsMode.displayAlternativeRideViews: return "Alternative Fahrtansichten anzeigen";
    }
  }
}