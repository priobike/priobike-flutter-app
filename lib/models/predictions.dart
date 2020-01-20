import 'package:bikenow/models/phase.dart';

class Prediction {
  String type;
  String timestamp;
  String lsa;
  String sg;
  String quality;
  List<Phase> phases;

  Prediction(
      {this.type,
      this.timestamp,
      this.lsa,
      this.sg,
      this.quality,
      this.phases});

  Prediction.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    timestamp = json['timestamp'];
    lsa = json['lsa'];
    sg = json['sg'];
    quality = json['quality'];
    if (json['phases'] != null) {
      phases = new List<Phase>();
      json['phases'].forEach((v) {
        phases.add(new Phase.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['timestamp'] = this.timestamp;
    data['lsa'] = this.lsa;
    data['sg'] = this.sg;
    data['quality'] = this.quality;
    if (this.phases != null) {
      data['phases'] = this.phases.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
