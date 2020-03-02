class Recommendation {
  String label;
  String timestamp;
  bool isGreen;
  double distance;
  int secondsToPhaseChange;
  double speedRecommendation;
  String error;

  Recommendation(
    this.label,
    this.timestamp,
    this.isGreen,
    this.distance,
    this.secondsToPhaseChange,
    this.speedRecommendation,
    this.error,
  );
}
