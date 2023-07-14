enum RideAssistMode { none, easy, interval, continuous }

extension RideAssistModeDescription on RideAssistMode {
  String get description {
    switch (this) {
      case RideAssistMode.none:
        return "Keine";
      case RideAssistMode.easy:
        return "Einfach";
      case RideAssistMode.interval:
        return "Intervall";
      case RideAssistMode.continuous:
        return "Kontinuierlich";
    }
  }
}

enum ModalityMode { audio, vibration }

extension ModalityModeDescription on ModalityMode {
  String get description {
    switch (this) {
      case ModalityMode.audio:
        return "Audio";
      case ModalityMode.vibration:
        return "Vibration";
    }
  }
}
