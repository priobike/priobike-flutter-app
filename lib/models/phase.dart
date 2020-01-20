class Phase {
  bool isGreen;
  String start;
  String end;
  int duration;

  Phase({this.isGreen, this.start, this.end, this.duration});

  Phase.fromJson(Map<String, dynamic> json) {
    isGreen = json['isGreen'];
    start = json['start'];
    end = json['end'];
    duration = json['duration'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['isGreen'] = this.isGreen;
    data['start'] = this.start;
    data['end'] = this.end;
    data['duration'] = this.duration;
    return data;
  }
}