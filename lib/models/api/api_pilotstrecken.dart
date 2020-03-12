class ApiPilotstrecken {
  String status;
  List<ApiStrecke> strecken;

  ApiPilotstrecken({this.status, this.strecken});

  ApiPilotstrecken.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['strecken'] != null) {
      strecken = new List<ApiStrecke>();
      json['strecken'].forEach((v) {
        strecken.add(new ApiStrecke.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    if (this.strecken != null) {
      data['strecken'] = this.strecken.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ApiStrecke {
  String id;
  String title;
  String startLabel;
  String destinationLabel;
  String description;
  double fromLat;
  double fromLon;
  double toLat;
  double toLon;

  ApiStrecke(
      {this.id,
      this.title,
      this.startLabel,
      this.destinationLabel,
      this.description,
      this.fromLat,
      this.fromLon,
      this.toLat,
      this.toLon});

  ApiStrecke.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    startLabel = json['startLabel'];
    destinationLabel = json['destinationLabel'];
    description = json['description'];
    fromLat = json['fromLat'];
    fromLon = json['fromLon'];
    toLat = json['toLat'];
    toLon = json['toLon'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['startLabel'] = this.startLabel;
    data['destinationLabel'] = this.destinationLabel;
    data['description'] = this.description;
    data['fromLat'] = this.fromLat;
    data['fromLon'] = this.fromLon;
    data['toLat'] = this.toLat;
    data['toLon'] = this.toLon;
    return data;
  }
}
