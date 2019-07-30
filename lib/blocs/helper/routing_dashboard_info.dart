
import 'package:bike_now/models/instruction.dart';
import 'package:bike_now/models/sg.dart';

class RoutingDashboardInfo{
  double currentSpeed;
  double recommendedSpeed;
  double diffSpeed;
  int secondsLeft;
  double distance;
  Instruction currentInstruction;
  SG nextSG;

  RoutingDashboardInfo(this.currentSpeed, this.recommendedSpeed, this.secondsLeft,
      this.distance, this.currentInstruction, this.nextSG){
    this.diffSpeed = recommendedSpeed - currentSpeed;
  }


}