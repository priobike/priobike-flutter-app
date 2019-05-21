import 'package:json_annotation/json_annotation.dart';

part 'location.g.dart';

@JsonSerializable()
class Location{
  double lat;
  double lon;
  double acc;
  double alt;
  double bear;
  double speed;
  DateTime time;
  String provider;
  int nxtLsa;
  String nxtSg;
  int cross;
  int dist;
  double speedKmh;
  double recSpeedKmh;
  double diffSpeedKmh;
  int locUpdIntvl;
  int leftSec;
  bool isGreen;
  bool isSim;
  bool isAtilt;
  num batPerc;

  Location(this.lat, this.lon, this.acc, this.alt, this.bear, this.speed,
      this.time, this.provider, this.nxtLsa, this.nxtSg, this.cross, this.dist,
      this.recSpeedKmh, this.locUpdIntvl, this.leftSec, this.isGreen,
      this.isSim, this.isAtilt, this.batPerc){
    this.speedKmh = speed *3.6;
    this.diffSpeedKmh = recSpeedKmh - speedKmh;
  }

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$LocationToJson(this);


}