import 'dart:convert';

enum PredictionMode {
  useSessionWrapper,
  usePredictor,
}

extension PredictionModeDescription on PredictionMode {
  String get description {
    switch (this) {
      case PredictionMode.useSessionWrapper:
        return "Sitzungsbasiertes, statistisches Verfahren (Empfohlen)";
      case PredictionMode.usePredictor:
        return "Clustering-Verfahren (Experimentell)";
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
