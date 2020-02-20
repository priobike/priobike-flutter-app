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

    if (speed == 0) {
      throw Exception('Geschwindigkeit 0 km/h, keine Ankunft');
    }

    int secondsToArrival = (distance / speed).round();

    if (time + secondsToArrival > vector.length) {
      throw Exception('Ankunftszeit außerhalb des Prognosevektors');
    }

    bool isGreenOnArrival =
        isGreen(vector[time + secondsToArrival], greentimeThreshold);

    if (isGreenOnArrival) {
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

      if (secondsToNextGreenPhase == 0) {
        return 0;
      }

      if (secondsToPreviousGreenPhase == 0) {
        return 0;
      }

      if (secondsToNextGreenPhase == null) {
        throw Exception('Es gibt keine NÄCHSTE Grünphase im Vektor');
      }

      if (secondsToPreviousGreenPhase == null) {
        throw Exception('Es gibt keine VORHERIGE Grünphase im Vektor');
      }

      double speedForNextPhase = distance / secondsToNextGreenPhase;
      double speedForPreviousPhase = distance / secondsToPreviousGreenPhase;

      double speedDiffNextPhase = (speedForNextPhase - speed) * 3.6;
      double speedDiffPreviousPhase = (speedForPreviousPhase - speed) * 3.6;

      print(speedDiffNextPhase);
      print(speedDiffPreviousPhase);

      return (speedDiffNextPhase.abs() <= speedDiffPreviousPhase.abs())
          ? speedDiffNextPhase.round()
          : speedDiffPreviousPhase.round();
    }
  }
}
