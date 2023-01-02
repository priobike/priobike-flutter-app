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
        return "Machine Learning";
    }
  }
}

extension SGSelectorServicePathParameter on SGSelector {
  String get servicePathParameter {
    switch (this) {
      case SGSelector.algorithmic:
        return "?matcher=legacy";
      case SGSelector.ml:
        return "?matcher=ml";
    }
  }
}
