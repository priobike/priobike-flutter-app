enum SpeechRate {
  fast,
  normal,
}

extension SpeechRateDescription on SpeechRate {
  String get description {
    switch (this) {
      case SpeechRate.fast:
        return "Schnell";
      case SpeechRate.normal:
        return "Normal";
    }
  }
}
