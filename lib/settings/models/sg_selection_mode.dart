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
        return "select_multi_lane";
    }
  }
}

enum SGSelectionMultiLaneMode {
  static,
  dynamic,
}

extension SGSelectionMultiLaneModeDescription on SGSelectionMultiLaneMode {
  String get description {
    switch (this) {
      case SGSelectionMultiLaneMode.static:
        return "Statisch";
      case SGSelectionMultiLaneMode.dynamic:
        return "Dynamisch";
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

enum SGSelectionModeDistanceToRoute {
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

extension SGSelectionModeDistanceToRouteMeter on SGSelectionModeDistanceToRoute {
  int get meter {
    switch (this) {
      case SGSelectionModeDistanceToRoute.five:
        return 5;
      case SGSelectionModeDistanceToRoute.ten:
        return 10;
      case SGSelectionModeDistanceToRoute.fifteen:
        return 15;
      case SGSelectionModeDistanceToRoute.twenty:
        return 20;
      case SGSelectionModeDistanceToRoute.twentyFive:
        return 25;
      case SGSelectionModeDistanceToRoute.thirty:
        return 30;
      case SGSelectionModeDistanceToRoute.thirtyFive:
        return 35;
      case SGSelectionModeDistanceToRoute.forty:
        return 40;
      case SGSelectionModeDistanceToRoute.fortyFive:
        return 45;
      case SGSelectionModeDistanceToRoute.fifty:
        return 50;
      case SGSelectionModeDistanceToRoute.fiftyFive:
        return 55;
      case SGSelectionModeDistanceToRoute.sixty:
        return 60;
    }
  }
}
