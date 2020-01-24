class Prediction {
  String timestamp;
  String lsa;
  String sg;
  String quality;
  String value;
  String greentimeTreshold;

  Prediction(
      {this.timestamp,
      this.lsa,
      this.sg,
      this.quality,
      this.value,
      this.greentimeTreshold});

  Prediction.fromJson(Map<String, dynamic> json) {
    timestamp = json['timestamp'];
    lsa = json['lsa'];
    sg = json['sg'];
    quality = json['quality'];
    value = json['value'];
    greentimeTreshold = json['greentimeTreshold'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['timestamp'] = this.timestamp;
    data['lsa'] = this.lsa;
    data['sg'] = this.sg;
    data['quality'] = this.quality;
    data['value'] = this.value;
    data['greentimeTreshold'] = this.greentimeTreshold;
    return data;
  }
}
