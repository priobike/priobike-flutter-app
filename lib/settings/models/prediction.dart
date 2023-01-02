enum PredictionMode {
  usePredictionService,
  usePredictor,
}

extension PredictionModeDescription on PredictionMode {
  String get description {
    switch (this) {
      case PredictionMode.usePredictionService:
        return "Standard";
      case PredictionMode.usePredictor:
        return "Experimentell";
    }
  }

  String get statusProviderSubPath {
    switch (this) {
      case PredictionMode.usePredictionService:
        return "prediction-monitor-nginx";
      case PredictionMode.usePredictor:
        return "predictor-nginx/status";
    }
  }
}
