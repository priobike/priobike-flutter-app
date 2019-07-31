class AddressToLocationResponse {
  int mode;
  int method;
  List<Place> places;

  AddressToLocationResponse({this.mode, this.method, this.places});

  AddressToLocationResponse.fromJson(Map<String, dynamic> json) {
    mode = json['mode'];
    method = json['method'];
    if (json['payload'] != null) {
      places = new List<Place>();
      json['payload'].forEach((v) { places.add(new Place.fromJson(v)); });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['mode'] = this.mode;
    data['method'] = this.method;
    if (this.places != null) {
      data['payload'] = this.places.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Place {
  int osmId;
  Address address;
  double importance;
  String icon;
  String lon;
  String displayName;
  String type;
  String osmType;
  String typeClass;
  int placeId;
  String lat;

  Place({this.osmId, this.address, this.importance, this.icon, this.lon, this.displayName, this.type, this.osmType, this.typeClass, this.placeId, this.lat});

  Place.fromJson(Map<String, dynamic> json) {
  osmId = json['osm_id'];
  address = json['address'] != null ? new Address.fromJson(json['address']) : null;
  importance = json['importance'];
  icon = json['icon'];
  lon = json['lon'];
  displayName = json['display_name'];
  type = json['type'];
  osmType = json['osm_type'];
  typeClass = json['class'];
  placeId = json['place_id'];
  lat = json['lat'];
  }

  Map<String, dynamic> toJson() {
  final Map<String, dynamic> data = new Map<String, dynamic>();
  data['"osm_id"'] = this.osmId;
  if (this.address != null) {
  data['"address"'] = this.address.toJson();
  }
  data['"importance"'] = this.importance;
  data['"icon"'] = '"${this.icon}"';
  data['"lon"'] = '"${this.lon}"';
  data['"display_name"'] = '"${this.displayName}"';
  data['"type"'] = '"${this.type}"';
  data['"osm_type"'] = '"${this.osmType}"';
  data['"class"'] = '"${this.typeClass}"';
  data['"place_id"'] = this.placeId;
  data['"lat"'] = '"${this.lat}"';
  return data;
  }
}

class Address {
  String country;
  String countryCode;
  String road;
  String city;
  String university;
  String neighbourhood;
  String postcode;
  String suburb;
  String state;
  String cityDistrict;

  Address({this.country, this.countryCode, this.road, this.city, this.university, this.neighbourhood, this.postcode, this.suburb, this.state, this.cityDistrict});

  Address.fromJson(Map<String, dynamic> json) {
    country = json['country'];
    countryCode = json['country_code'];
    road = json['road'];
    city = json['city'];
    university = json['university'];
    neighbourhood = json['neighbourhood'];
    postcode = json['postcode'];
    suburb = json['suburb'];
    state = json['state'];
    cityDistrict = json['city_district'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['"country"'] = '"${this.country}"';
    data['"country_code"'] = '"${this.countryCode}"';
    data['"road"'] = '"${this.road}"';
    data['"city"'] = '"${this.city}"';
    data['"university"'] = '"${this.university}"';
    data['"neighbourhood"'] = '"${this.neighbourhood}"';
    data['"postcode"'] = '"${this.postcode}"';
    data['"suburb"'] = '"${this.suburb}"';
    data['"state"'] = '"${this.state}"';
    data['"city_district"'] = '"${this.cityDistrict}"';
    return data;
  }
}