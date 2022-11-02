enum SGLabelsMode {
  disabled,
  enabled,
}

extension SGLabelsModeDescription on SGLabelsMode {
  String get description {
    switch (this) {
      case SGLabelsMode.enabled:
        return "Signalgruppen-Labels in Routing-Ansicht anzeigen";
      case SGLabelsMode.disabled:
        return "Keine Signalgruppen-Labels anzeigen";
    }
  }
}
