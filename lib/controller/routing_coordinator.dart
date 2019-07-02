import 'controller.dart';
import 'package:bike_now/models/models.dart';

class RoutingCoordinator{
  RoutingController routingController;
  PredictionController predictionController;
  SubscriptionController subscriptionController;
  LocationController locationController;

  RoutingCoordinator(this.routingController, this.predictionController,
      this.subscriptionController, this.locationController);

  void run(){
    if (routingController.ghNodes.isNotEmpty){
      calculateDistances();
      updatePredictions();
      updateLocationController();
    }
  }
  void calculateDistances(){
    if (locationController.currentLocation != null){
      var latlng = LatLng(locationController.currentLocation.latitude, locationController.currentLocation.longitude);
      routingController.calculateDistances(routingController.orderedLSAs, latlng);
      routingController.calculateDistances(routingController.sgs, latlng);
      routingController.calculateDistances(routingController.ghNodes, latlng);
      routingController.calculateDistances(routingController.route.instructions, latlng);
    }
  }
  void updatePredictions(){
    if (locationController.currentLocation != null) {
      var latlng = LatLng(locationController.currentLocation.latitude,
          locationController.currentLocation.longitude);

      predictionController.setNextGHNode();
      predictionController.setNextSG();
      predictionController.setNextValidSG();
      predictionController.setClosestSG();
      predictionController.setClosestValidSG();
      predictionController.setNextLSA();
      predictionController.setNextInstruction();

      if (predictionController.nextSG != predictionController.closestSG) {
        predictionController.nextSG = predictionController.closestSG;
      }

      predictionController.setNextValidPhase(locationController.currentLocation.speed);
      predictionController.setCurrentPhase();
      predictionController.setNextSGGreenState();
    }
  }
  void updateLocationController(){
    if(predictionController.nextSG.distance != null){
      //locationController.updateLocationAccuracy(for: distanceToNextSG)

    }
  }

  void reset() {
    predictionController.unsubscribe();
    subscriptionController.reset();
    routingController.reset();
    predictionController.reset();
  }



}