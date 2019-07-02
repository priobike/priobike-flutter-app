import 'package:flutter/material.dart';
import 'package:bike_now/models/lsa_prediction.dart';
import 'package:bike_now/models/models.dart';
import 'package:bike_now/controller/subscription_controller.dart';
import 'package:bike_now/controller/routing_controller.dart';

class PredictionController{

  List<LSAPrediction> predictions = [];
  Phase currentPhase;
  Phase nextValidPhase;
  Instruction nextInstruction;
  SG nextSG;
  LSA nextLSA;
  GHNode nextGHNode;
  SG nextValidSG;
  SG closestSG;
  SG closestValidSG;
  RoutingController routingController;
  SubscriptionController subscriptionController;

  PredictionController(this.subscriptionController, this.routingController);

  void reset(){
    currentPhase = null;
    nextValidPhase = null;
    nextInstruction = null;
    nextSG = null;
    nextLSA = null;
    nextGHNode = null;
    nextValidSG = null;
    closestSG = null;
    closestValidSG = null;
  }

  void unsubscribe(){
    subscriptionController.unsubscribe(nextSG);
    subscriptionController.unsubscribe(closestSG);

  }
  void setCurrentPhase(){
    currentPhase = nextSG?.phases.firstWhere((phase) => phase.getCurrentPhase() != null);
  }
  void setNextValidPhase(double speed ){
    nextValidPhase = nextSG?.phases.firstWhere((phase) => (!phase.isInThePast && phase.getValidPhase(speed) != null));
  }
  void setNextGHNode(){
    nextGHNode = routingController.route.getNextGHNode(routingController.ghNodes, 0.5, true);
  }
  void setNextInstruction(){
    nextInstruction = routingController.route.instructions.firstWhere((instruction) => !instruction.isCrossed);
  }
  void setNextLSA(){
    nextLSA = nextSG.parentLSA;
  }
  void setNextSG(){
    nextSG = routingController.sgs.firstWhere((sg) => !sg.isCrossed);
  }
  void setNextValidSG(){
    nextValidSG = routingController.sgs.firstWhere((sg) => !sg.isCrossed && sg.hasPredictions);
  }
  void setNextSGGreenState(){
    if (currentPhase != null){
      nextSG.isGreen = currentPhase.isGreen;
    }
  }
  void setClosestSG(){
    var sortedSGs = routingController.sgs;
    sortedSGs.sort((a,b) => a.distance.compareTo(b.distance));
    closestValidSG = sortedSGs.firstWhere((sg) => !sg.isCrossed);
  }
  void setClosestValidSG(){
    var sortedSGs = routingController.sgs;
    sortedSGs.sort((a,b) => a.distance.compareTo(b.distance));
    closestValidSG = sortedSGs.firstWhere((sg) => !sg.isCrossed && sg.hasPredictions);
  }

}