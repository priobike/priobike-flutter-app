class PredictionAlgorithm {
  static bool green(
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
      bool greenThen = green(vector[i], greentimeThreshold);

      if ((greenNow && !greenThen) || (!greenNow && greenThen)) {
        break;
      }

      secondsToPhaseChange++;
    }

    return secondsToPhaseChange;
  }

  static double speedRecommendation(
    List<double> vector,
    double distance, // meter
    double speed, // meter pro sekunde
    double greentimeThreshold,
    int time,
  ) {
    if (speed == 0) {
      throw Exception('Geschwindigkeit 0 km/h, keine Ankunft');
    }

    int secondsToArrival = (distance / speed).round();

    if (time + secondsToArrival > vector.length) {
      throw Exception('Ankunftszeit außerhalb des Prognosevektors');
    }

    bool greenOnArrival =
        green(vector[time + secondsToArrival], greentimeThreshold);

    if (greenOnArrival) {
      //
      // Die SG wird bei Grün passiert -> alles okay, keine Änderung notwendig
      //
      return 0;
    } else {
      //
      // Der Radfahrende erreicht die SG bei Rot
      // Suche nächste Grünphase und berechne Zeit bis zum Start

      int secondsToNextGreenPhase;
      for (var i = time + secondsToArrival; i < vector.length; i++) {
        bool greenThen = green(vector[i], greentimeThreshold);

        if (greenThen) {
          secondsToNextGreenPhase = i - time;
          break;
        }
      }

      // Suche vorherige Grünphase und berechne Zeit bis zum Ende
      int secondsToPreviousGreenPhase;
      for (var i = time + secondsToArrival; i >= time; i--) {
        bool greenThen = green(vector[i], greentimeThreshold);

        if (greenThen) {
          secondsToPreviousGreenPhase = i - time;
          break;
        }
      }

      if (secondsToNextGreenPhase == 0) {
        return 0;
      }

      if (secondsToPreviousGreenPhase == 0) {
        return 0;
      }

      double speedDiffNextPhase;
      if (secondsToNextGreenPhase != null) {
        double speedForNextPhase = distance / secondsToNextGreenPhase;
        speedDiffNextPhase = (speedForNextPhase - speed) * 3.6;
        print(speedForNextPhase * 3.6);
      }

      double speedDiffPreviousPhase;
      if (secondsToPreviousGreenPhase != null) {
        double speedForPreviousPhase = distance / secondsToPreviousGreenPhase;
        speedDiffPreviousPhase = (speedForPreviousPhase - speed) * 3.6;
        print(speedForPreviousPhase * 3.6);
      }

      if (speedDiffPreviousPhase == null && speedDiffNextPhase == null)
        throw Exception('Berechnung der Prognose nicht möglich..');

      if (speedDiffPreviousPhase == null && speedDiffNextPhase != null)
        return speedDiffNextPhase;

      if (speedDiffPreviousPhase != null && speedDiffNextPhase == null)
        return speedDiffPreviousPhase;

      return (speedDiffNextPhase.abs() <= speedDiffPreviousPhase.abs())
          ? speedDiffNextPhase
          : speedDiffPreviousPhase;
    }
  }
}
