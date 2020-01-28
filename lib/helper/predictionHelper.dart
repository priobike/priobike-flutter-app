class PredictionHelper {
  static bool calculateIsGreen(
    int t,
    List<double> values,
    double greentimeThreshold,
  ) {
    return values[t] > greentimeThreshold;
  }

  static bool secondsToPhaseChange(
    int t,
    List<double> values,
    double greentimeThreshold,
  ) {
    return values[t] > greentimeThreshold;
  }
}
