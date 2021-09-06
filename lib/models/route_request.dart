class RouteRequest {
  String sessionId;
  Position from;
  Position to;

  RouteRequest({this.sessionId, this.from, this.to});

  RouteRequest.fromJson(Map<String, dynamic> json) {
    sessionId = json['sessionId'];
    from = json['from'] != null ? new Position.fromJson(json['from']) : null;
    to = json['to'] != null ? new Position.fromJson(json['to']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sessionId'] = this.sessionId;
    if (this.from != null) {
      data['from'] = this.from.toJson();
    }
    if (this.to != null) {
      data['to'] = this.to.toJson();
    }
    return data;
  }
}

class Position {
  double lon;
  double lat;

  Position({this.lon, this.lat});

  Position.fromJson(Map<String, dynamic> json) {
    lon = json['lon'];
    lat = json['lat'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lon'] = this.lon;
    data['lat'] = this.lat;
    return data;
  }
}
