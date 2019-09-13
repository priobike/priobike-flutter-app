import 'controller.dart';
import 'package:bike_now_flutter/models/models.dart';

class RoutingCoordinator {
  RoutingController routingController;
  PredictionController predictionController;
  SubscriptionController subscriptionController;
  LocationController locationController;

  RoutingCoordinator(this.routingController, this.predictionController,
      this.subscriptionController, this.locationController);

  void run() {
    if (routingController.ghNodes.isNotEmpty) {
      calculateDistances();
      updatePredictions();
      updateLocationController();
    }
  }

  void calculateDistances() {
    if (locationController.currentLocation != null) {
      var latlng = LatLng(
          locationController.currentLocation.latitude,
          locationController.currentLocation.longitude,
          locationController.currentLocation.accuracy);
      try {
        routingController.calculateDistances(routingController.sgs, latlng);
      } catch (e) {
        e.toString();
      }
      try {
        routingController.calculateDistances(
            routingController.orderedLSAs, latlng);
      } catch (e) {
        e.toString();
      }

      try {
        routingController.calculateDistances(routingController.ghNodes, latlng);
      } catch (e) {
        e.toString();
      }
      try {
        routingController.calculateDistances(
            routingController.route.instructions, latlng);
      } catch (e) {
        e.toString();
      }
    }
  }

  void updatePredictions() {
    if (locationController.currentLocation != null) {
      try {
        predictionController.setNextGHNode();
      } catch (e) {
        e.toString();
      }
      try {
        predictionController.setNextSG();
      } catch (e) {
        e.toString();
      }
      try {
        predictionController.setNextValidSG();
      } catch (e) {
        e.toString();
      }
      try {
        predictionController.setClosestSG();
      } catch (e) {
        e.toString();
      }
      try {
        predictionController.setClosestValidSG();
      } catch (e) {
        e.toString();
      }
      try {
        predictionController.setNextLSA();
      } catch (e) {
        e.toString();
      }
      try {
        predictionController.setNextInstruction();
      } catch (e) {
        e.toString();
      }

      if (predictionController.nextSG != predictionController.closestSG) {
        predictionController.nextSG = predictionController.closestSG;
      }

      try {
        predictionController
            .setNextValidPhase(locationController.currentLocation.speed);
      } catch (e) {
        e.toString();
      }
      try {
        predictionController.setCurrentPhase();
      } catch (e) {
        e.toString();
      }
      try {
        predictionController.setNextSGGreenState();
      } catch (e) {
        e.toString();
      }
    }
  }

  void updateLocationController() {
    if (predictionController.nextSG.distance != null) {
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
