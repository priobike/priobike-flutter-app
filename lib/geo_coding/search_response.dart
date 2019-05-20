import 'package:json_annotation/json_annotation.dart';

@JsonSerializable(nullable: false)
class PlaceList {
  final List<Place> places;

  PlaceList(this.places);

  factory PlaceList.fromJson(List<dynamic> parsedJson) {
    List<Place> places = new List<Place>();
    places = parsedJson.map((i)=>Place.fromJson(i)).toList();
    return new PlaceList(places);
  }
}

@JsonSerializable(nullable: false)
class Place {
  final int placeId;
  final String licence;
  final String osmType;
  final int osmId;
  final List<String> boundingbox;
  final double lat;
  final double lon;
  final String displayName;
  final String adress_class;
  final String adress_type;
  final double importance;

  Place({this.placeId, this.licence, this.osmType, this.osmId, this.boundingbox, this.lat, this.lon, this.displayName, this.adress_class, this.adress_type, this.importance});

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
        placeId : json['place_id'] as int,
        licence : json['licence'] as String,
        osmType : json['osm_type'] as String,
        osmId : json['osm_id'] as int,
        boundingbox : json['boundingbox'].cast<String>() as List<String>,
        lat : double.parse(json['lat']),
        lon : double.parse(json['lon']),
        displayName : json['display_name'] as String,
        adress_class : json['class'] as String,
        adress_type : json['type'] as String,
        importance : json['importance'] as double
    );
  }
}