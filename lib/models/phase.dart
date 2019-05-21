import 'package:bike_now/models/sg.dart';

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

  double getRecommendedSpeed(){

  }

  double getRecommendedSpeedDifference(){

  }

  Phase getValidPhase(){

  }

  Phase getCurrentPhase(){

  }



}