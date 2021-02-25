import 'dart:convert';

class Recommendation {
  String label;
  int countdown;
  double distance;
  double speedRec;
  double speedDiff;
  bool isGreen;
  bool error;
  String errorMessage;

  Recommendation(
      {this.label,
      this.countdown,
      this.distance,
      this.speedRec,
      this.speedDiff,
      this.isGreen,
      this.error,
      this.errorMessage});

  Recommendation.fromJson(Map<String, dynamic> json) {
    label = json['label'];
    countdown = json['countdown'];
    distance = json['distance'].toDouble();
    speedRec = json['speedRec'].toDouble();
    speedDiff = json['speedDiff'].toDouble();
    isGreen = json['isGreen'];
    error = json['error'];
    errorMessage = json['errorMessage'];
  }

  String toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['label'] = this.label;
    data['countdown'] = this.countdown;
    data['distance'] = this.distance;
    data['speedRec'] = this.speedRec;
    data['speedDiff'] = this.speedDiff;
    data['isGreen'] = this.isGreen;
    data['error'] = this.error;
    data['errorMessage'] = this.errorMessage;
    return json.encode(data);
  }
}
