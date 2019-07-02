import 'package:bike_now/controller/subscription_controller.dart';
import 'package:bike_now/models/models.dart' as Models;
import 'package:flutter/material.dart';
import 'package:bike_now/models/abstract_classes/locatable.dart';
import 'package:bike_now/models/abstract_classes/locatable_and_crossable.dart';

class RoutingController{
  SubscriptionController subscriptionController;
  Models.Route route;
  List<Models.LSA> orderedLSAs;
  Map<int, Models.LSA> lsas;
  List<Models.SG> sgs;
  List<Models.GHNode> ghNodes;
  String routeId;

  void handleSGSubscribe(Models.SG sg){
    subscriptionController.subscribe(sg);

  }
  void handleSGUnSubscribe(Models.SG sg){
    subscriptionController.unsubscribe(sg);

  }

  RoutingController(this.subscriptionController);

  void reset(){
    route = null;
  }

  Models.LSA getLSA(int Id){
    orderedLSAs.firstWhere((lsa) => lsa.id == Id);
  }
  Models.SG getSG(int id){
    return sgs.firstWhere((sg) => sg.id == id);
  }
  List<Models.GHNode> getGHNodes(bool onlyIfCrossed){
    return ghNodes.where((ghNode) {
      if (onlyIfCrossed){
        return ghNode.isCrossed;
      }else{
        return true;
      }
    }).toList();
  }

  setRoute(Models.Route route){
    this.route = route;
    orderedLSAs = route.getLSAs();
    lsas = route.getLSADictionary();
    ghNodes = route.getGHNodes(true);
  }

  setLSAs(){
    orderedLSAs.forEach((lsa) => lsa.sgs.forEach((sg){
      sg.uniqueName = "${lsa.id}#${sg.name}";
      sg.parentLSA = lsa;
      sg.handleSGSubscribtion = handleSGSubscribe;
      sg.handleSGUnSubscribe = handleSGUnSubscribe;

      sgs.add(sg);
    }));
  }

  setGHNodes(){
    ghNodes.forEach((ghNode) {
      var sg = getSG(ghNode.id);
      if (sg!=null){
        sg.referencedGHNode = ghNode;
        ghNode.referencedSG = sg;
      }

    });
  }

  void calculateDistances(List<LocatableAndCrossable> locations, Models.LatLng currentLocation){
    var sorted = locations.where((locatable)=>!locatable.isCrossed).toList()
        .map((location) {
          location.distance = location.calculateDistanceTo(currentLocation);
          return location;

    }).toList();
    sorted.sort((a,b){
      a.distance.compareTo(b.distance);
    });
    sorted.forEach((location){
      var isCrossed = location.calculateIsCrossed(location.distance, currentLocation.accuracy);
      location.isCrossed = isCrossed;
    });


  }


}