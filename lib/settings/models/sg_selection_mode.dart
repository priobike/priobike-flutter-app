enum SGSelectionMode {
  single,
  crossing,
}

extension SGSelectionModeDescription on SGSelectionMode {
  String get description {
    switch (this) {
      case SGSelectionMode.single:
        return "Tacho";
      case SGSelectionMode.crossing:
        return "Spuren";
    }
  }
}

extension SGSelectionModePath on SGSelectionMode {
  String get path {
    switch (this) {
      case SGSelectionMode.single:
        return "select";
      case SGSelectionMode.crossing:
        return "select_crossing";
    }
  }
}
