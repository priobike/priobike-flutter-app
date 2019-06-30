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

  Address(
      {this.country,
        this.countryCode,
        this.road,
        this.city,
        this.university,
        this.neighbourhood,
        this.postcode,
        this.suburb,
        this.state,
        this.cityDistrict});

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
    data['country'] = this.country;
    data['country_code'] = this.countryCode;
    data['road'] = this.road;
    data['city'] = this.city;
    data['university'] = this.university;
    data['neighbourhood'] = this.neighbourhood;
    data['postcode'] = this.postcode;
    data['suburb'] = this.suburb;
    data['state'] = this.state;
    data['city_district'] = this.cityDistrict;
    return data;
  }
}