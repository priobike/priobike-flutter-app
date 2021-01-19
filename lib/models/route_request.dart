class RouteRequest {
  String id;
  double fromLat;
  double fromLon;
  double toLat;
  double toLon;

  RouteRequest({this.id, this.fromLat, this.fromLon, this.toLat, this.toLon});

  RouteRequest.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fromLat = json['fromLat'];
    fromLon = json['fromLon'];
    toLat = json['toLat'];
    toLon = json['toLon'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['fromLat'] = this.fromLat;
    data['fromLon'] = this.fromLon;
    data['toLat'] = this.toLat;
    data['toLon'] = this.toLon;
    return data;
  }
}