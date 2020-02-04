class ApiPrediction {
  double greentimeThreshold;
  String lsaId;
  String sgName;
  double qualityfactor;
  String startTime;
  double availability;
  List<double> value;
  String timestamp;

  ApiPrediction(
      {this.greentimeThreshold,
      this.lsaId,
      this.sgName,
      this.qualityfactor,
      this.startTime,
      this.availability,
      this.value,
      this.timestamp});

  ApiPrediction.fromJson(Map<String, dynamic> json) {
    greentimeThreshold = json['greentimeThreshold'].toDouble();
    lsaId = json['lsaId'];
    sgName = json['sgName'];
    qualityfactor = json['qualityfactor'].toDouble();
    startTime = json['startTime'];
    availability = json['availability'].toDouble();
    timestamp = json['timestamp'];

    value = [];
    json['value'].forEach((item) => value.add(item.toDouble()));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['greentimeThreshold'] = this.greentimeThreshold;
    data['lsaId'] = this.lsaId;
    data['sgName'] = this.sgName;
    data['qualityfactor'] = this.qualityfactor;
    data['startTime'] = this.startTime;
    data['availability'] = this.availability;
    data['value'] = this.value;
    data['timestamp'] = this.timestamp;
    return data;
  }
}
