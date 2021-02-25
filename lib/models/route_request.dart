class RouteRequest {
  double fromLat;
  double fromLon;
  double toLat;
  double toLon;

  RouteRequest({this.fromLat, this.fromLon, this.toLat, this.toLon});

  RouteRequest.fromJson(Map<String, dynamic> json) {
    fromLat = json['fromLat'];
    fromLon = json['fromLon'];
    toLat = json['toLat'];
    toLon = json['toLon'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['fromLat'] = this.fromLat;
    data['fromLon'] = this.fromLon;
    data['toLat'] = this.toLat;
    data['toLon'] = this.toLon;
    return data;
  }
}
