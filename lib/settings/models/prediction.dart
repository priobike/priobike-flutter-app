enum PredictionMode {
  usePredictionService,
  usePredictor,
  hybrid,
}

extension PredictionModeDescription on PredictionMode {
  String get description {
    switch (this) {
      case PredictionMode.usePredictionService:
        return "Standard";
      case PredictionMode.usePredictor:
        return "Experimentell";
      case PredictionMode.hybrid:
        return "Hybrid";
    }
  }

  String get statusProviderSubPath {
    switch (this) {
      case PredictionMode.usePredictionService:
        return "prediction-monitor-nginx";
      case PredictionMode.usePredictor:
        return "predictor-nginx/status";
      case PredictionMode.hybrid:
        return "prediction-monitor-nginx";
    }
  }
}
