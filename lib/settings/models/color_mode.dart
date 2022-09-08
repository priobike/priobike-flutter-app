enum ColorMode {
  light,
  dark,
  system
}

extension ColorModeDescription on ColorMode {
  String get description {
    switch (this) {
      case ColorMode.light: return "Lightmode";
      case ColorMode.dark: return "Darkmode";
      case ColorMode.system: return "Wie das System";
    }
  }
}