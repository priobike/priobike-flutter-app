enum SGSelector {
  algorithmic,
  ml,
}

extension SGSelectorDescription on SGSelector {
  String get description {
    switch (this) {
      case SGSelector.algorithmic:
        return "Algorithmisch";
      case SGSelector.ml:
        return "KI (Experimentell)";
    }
  }
}

extension SGSelectorServicePathParameter on SGSelector {
  String get servicePathParameter {
    switch (this) {
      case SGSelector.algorithmic:
        return "legacy";
      case SGSelector.ml:
        return "ml";
    }
  }
}
