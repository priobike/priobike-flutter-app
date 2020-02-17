class Recommendation {
  String label;
  String timestamp;
  bool isGreen;
  int distance;
  int secondsToPhaseChange;
  int speedRecommendation;
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
