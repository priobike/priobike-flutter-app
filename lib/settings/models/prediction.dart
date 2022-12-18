enum PredictionMode {
  useSessionWrapper,
  usePredictor,
}

extension PredictionModeDescription on PredictionMode {
  String get description {
    switch (this) {
      case PredictionMode.useSessionWrapper:
        return "Sitzungsbasiertes, statistisches Verfahren";
      case PredictionMode.usePredictor:
        return "Clustering-Verfahren (Experimentell)";
    }
  }
}
