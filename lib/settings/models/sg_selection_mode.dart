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

enum SGSelectionModeBearingDiff {
  five,
  ten,
  fifteen,
  twenty,
  twentyFive,
  thirty,
  thirtyFive,
  forty,
  fortyFive,
  fifty,
  fiftyFive,
  sixty,
}

extension SGSelectionModeBearingDiffDegree on SGSelectionModeBearingDiff {
  int get degree {
    switch (this) {
      case SGSelectionModeBearingDiff.five:
        return 5;
      case SGSelectionModeBearingDiff.ten:
        return 10;
      case SGSelectionModeBearingDiff.fifteen:
        return 15;
      case SGSelectionModeBearingDiff.twenty:
        return 20;
      case SGSelectionModeBearingDiff.twentyFive:
        return 25;
      case SGSelectionModeBearingDiff.thirty:
        return 30;
      case SGSelectionModeBearingDiff.thirtyFive:
        return 35;
      case SGSelectionModeBearingDiff.forty:
        return 40;
      case SGSelectionModeBearingDiff.fortyFive:
        return 45;
      case SGSelectionModeBearingDiff.fifty:
        return 50;
      case SGSelectionModeBearingDiff.fiftyFive:
        return 55;
      case SGSelectionModeBearingDiff.sixty:
        return 60;
    }
  }
}
