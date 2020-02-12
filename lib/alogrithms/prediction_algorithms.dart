class PredictionAlgorithm {
  static bool isGreen(
    double value,
    double greentimeThreshold,
  ) =>
      value >= greentimeThreshold;

  static int secondsToPhaseChange(
    List<double> vector,
    bool greenNow,
    double greentimeThreshold,
    int t,
  ) {
    int secondsToPhaseChange = 0;
    for (var i = t; i < vector.length; i++) {
      bool greenThen = isGreen(vector[i], greentimeThreshold);

      if ((greenNow && !greenThen) || (!greenNow && greenThen)) {
        break;
      }

      secondsToPhaseChange++;
    }

    return secondsToPhaseChange;
  }

  static int speedRecommendation(
    List<double> vector,
    double distance, // meter
    double speed, // meter pro sekunde
    double greentimeThreshold,
    int time,
  ) {
    int secondsToArrival = (distance / speed).round();

    bool isGreenOnArrival =
        isGreen(vector[time + secondsToArrival], greentimeThreshold);

    if (isGreenOnArrival) {
      return 0; // Die SG wird bei Grün passiert -> alles okay, keine Änderung notwendig
    } else {
      // Der Radfahrende erreicht die SG bei Rot
      // Suche nächste Grünphase und berechne Zeit bis zum Start
      int secondsToNextGreenPhase;
      for (var i = time + secondsToArrival; i < vector.length; i++) {
        bool greenThen = isGreen(vector[i], greentimeThreshold);

        if (greenThen) {
          secondsToNextGreenPhase = i - time;
          break;
        }
      }

      // Suche vorherige Grünphase und berechne Zeit bis zum Ende
      int secondsToPreviousGreenPhase;
      for (var i = time + secondsToArrival; i >= 0; i--) {
        bool greenThen = isGreen(vector[i], greentimeThreshold);

        if (greenThen) {
          secondsToPreviousGreenPhase = i - time;
          break;
        }
      }

      double speedForNextPhase = (distance / secondsToNextGreenPhase);
      double speedForPreviousPhase = (distance / secondsToPreviousGreenPhase);

      double speedDiffNextPhase = ((speedForNextPhase -speed) * 3.6);
      double speedDiffPreviousPhase = ((speedForPreviousPhase -speed) * 3.6);

      print(speedDiffNextPhase);
      print(speedDiffPreviousPhase);

      return speedDiffNextPhase.round();
    }
  }
}
