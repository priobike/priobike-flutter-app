
import 'package:bike_now_flutter/models/location.dart';
import 'package:json_annotation/json_annotation.dart';

part 'location_plus.g.dart';


@JsonSerializable()
class LocationPlus{
  @JsonKey(ignore: true)
  int id = 0;

  @JsonKey(name: 'lat')
  double latitude = 0.0;

  @JsonKey(name: 'lon')
  double longitude = 0.0;

  @JsonKey(name: 'acc')
  double accuracy = 0.0;

  @JsonKey(name: 'alt')
  double altitude = 0.0;

  @JsonKey(name: 'bear')
  double bearing = 0.0;

  @JsonKey(name: 'speed')
  double speed = 0.0;

  @JsonKey(name: 'speedKmh')
  double speedKmh = 0.0;

  @JsonKey(name: 'time')
  String time = DateTime.now().toIso8601String();

  @JsonKey(name: 'provider')
  String provider = "none";

  @JsonKey(name: 'nextLsa')
  int nextLsaId = -1;

  @JsonKey(name: 'nextSg')
  String nextSgName = "none";

  @JsonKey(name: 'dist')
  int distanceNextSG = -1;

  @JsonKey(name: 'cross')
  int crossAlgo = -1;

  @JsonKey(name: 'recSpeedKmh')
  int recommendedSpeedKmh = -1;

  @JsonKey(name: 'diffSpeedKmh')
  double differenceSpeedKmh = 0.0;

  @JsonKey(name: 'locUpdIntvl')
  int locationUpdateInterval = -1;

  @JsonKey(name: 'leftSec')
  int remainingPhaseSeconds = -1;

  @JsonKey(name: 'lastCountdown')
  int lastCountdownThisLocation = 0;

  @JsonKey(name: 'isGreen')
  bool isGreen = false;

  @JsonKey(name: 'isSim')
  bool isSimulation = false;

  @JsonKey(name: 'isDebug')
  bool isDebug = false;

  @JsonKey(name: 'errorReportCode')
  int errorReportCode = 0;

  @JsonKey(name: 'isAtilt')
  bool isAtilt = false;

  @JsonKey(name: 'batPerc')
  int batteryLevel = -1;

  @JsonKey(name: 'rideID')
  String rideID = "none";

  @JsonKey(name: 'nextInstructionText')
  String nextInstructionText = "none";

  @JsonKey(name: 'nextInstructionSig')
  String nextInstructionSig = "none";

  @JsonKey(name: 'nextSgUniqueName')
  String nextSg = "none";

  @JsonKey(name: 'nextGHNode')
  int nextGhNode = 0;
}