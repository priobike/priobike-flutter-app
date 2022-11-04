enum DatastreamMode {
  disabled,
  enabled,
}

extension DatastreamModeDescription on DatastreamMode {
  String get description {
    switch (this) {
      case DatastreamMode.enabled:
        return "Echtzeitdaten der Signalgruppen anzeigen";
      case DatastreamMode.disabled:
        return "Keine Echtzeitdaten anzeigen";
    }
  }
}
