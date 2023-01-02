enum Rerouting {
  disabled,
  enabled,
}

extension ReroutingDescription on Rerouting {
  String get description {
    switch (this) {
      case Rerouting.enabled:
        return "Bei Abweichung von Route (Empfohlen)";
      case Rerouting.disabled:
        return "Keine Neuberechnung";
    }
  }
}
