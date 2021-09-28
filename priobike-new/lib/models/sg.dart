class Sg {
  int? index;
  double? lat;
  double? lon;

  Sg({this.index, this.lat, this.lon});

  Sg.fromJson(Map<String, dynamic> json) {
    index = json['index'];
    lat = json['lat'];
    lon = json['lon'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['index'] = index;
    data['lat'] = lat;
    data['lon'] = lon;
    return data;
  }
}
