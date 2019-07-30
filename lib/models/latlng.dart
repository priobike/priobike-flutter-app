import 'package:json_annotation/json_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as Google;


part 'latlng.g.dart';


@JsonSerializable()
class LatLng{
  double lat;
  double lng;
  double accuracy = 0;
  double speed = 0;
  // Estimated horizontal accuracy of this location, radial, in meters


  LatLng(this.lat, this.lng, [this.accuracy = 0, this.speed = 0]);

  factory LatLng.fromJson(Map<String, dynamic> json) => _$LatLngFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$LatLngToJson(this);

  Google.LatLng toGoogleLatLng(){
    return Google.LatLng(lat,lng);

  }


}