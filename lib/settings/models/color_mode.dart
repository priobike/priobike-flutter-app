enum ColorMode { light, dark, system }

extension ColorModeDescription on ColorMode {
  String get description {
    switch (this) {
      case ColorMode.light:
        return "Hell";
      case ColorMode.dark:
        return "Dunkel";
      case ColorMode.system:
        return "System";
    }
  }
}
