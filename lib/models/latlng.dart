import 'package:json_annotation/json_annotation.dart';
import 'package:mapbox_gl/mapbox_gl.dart' as MapLatLng;

part 'latlng.g.dart';


@JsonSerializable()
class LatLng{
  double lat;
  double lng;

  LatLng(this.lat, this.lng);

  factory LatLng.fromJson(Map<String, dynamic> json) => _$LatLngFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$LatLngToJson(this);

  MapLatLng.LatLng toMapBoxCoordinates(){
    return MapLatLng.LatLng(lat, lng);

  }


}