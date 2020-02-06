class PredictionAlgorithm {
  static bool isGreen(double value, double greentimeThreshold) =>
      value >= greentimeThreshold;

  static int secondsToPhaseChange(
      List<double> vector, bool greenNow, double greentimeThreshold, int t) {
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
}
