import 'package:bike_now/models/sg.dart';
import 'package:json_annotation/json_annotation.dart';

part 'phase.g.dart';

@JsonSerializable()
class Phase{
  String start;
  String end;
  int duration;
  bool isGreen = false;
  DateTime endDate;
  DateTime startDate;
  DateTime midDate;

  int durationLeft;
  double distance;

  double speedToReachStart;
  double speedToReachMid;
  double speedToReachEnd;
  SG parentSG;
  bool isInThePast;


  Phase(this.start, this.end, this.duration, this.isGreen, this.endDate,
      this.startDate, this.midDate, this.durationLeft, this.distance,
      this.speedToReachStart, this.speedToReachMid, this.speedToReachEnd,
      this.parentSG, this.isInThePast);

  factory Phase.fromJson(Map<String, dynamic> json) => _$PhaseFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$PhaseToJson(this);

  double getRecommendedSpeed(){

  }

  double getRecommendedSpeedDifference(){

  }

  Phase getValidPhase(){

  }

  Phase getCurrentPhase(){

  }



}