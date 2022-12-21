enum PredictionMode {
  useSessionWrapper,
  usePredictor,
}

extension PredictionModeDescription on PredictionMode {
  String get description {
    switch (this) {
      case PredictionMode.useSessionWrapper:
        return "Session Wrapper (Standard)";
      case PredictionMode.usePredictor:
        return "Predictor (Experimentell)";
    }
  }

  String get statusProviderSubPath {
    switch (this) {
      case PredictionMode.useSessionWrapper:
        return "prediction-monitor-nginx";
      case PredictionMode.usePredictor:
        return "predictor-nginx/status";
    }
  }
}
