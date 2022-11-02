enum Rerouting {
  disabled,
  enabled,
}

extension ReroutingDescription on Rerouting {
  String get description {
    switch (this) {
      case Rerouting.enabled:
        return "Route bei Abweichung neu berechnen (experimentell)";
      case Rerouting.disabled:
        return "Keine neue Route während der Fahrt berechnen";
    }
  }
}
