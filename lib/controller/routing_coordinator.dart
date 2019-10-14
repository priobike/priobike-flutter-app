import 'dart:async';

import 'package:bike_now_flutter/Services/setting_service.dart';
import 'package:bike_now_flutter/database/database_helper.dart';
import 'package:bike_now_flutter/database/database_locations.dart';
import 'package:bike_now_flutter/models/location_plus.dart';

import 'controller.dart';
import 'package:bike_now_flutter/models/models.dart';

class RoutingCoordinator {
  RoutingController routingController;
  PredictionController predictionController;
  SubscriptionController subscriptionController;
  LocationController locationController;
  Timer _saveLocationTimer;
  Timer _transmitLocationTimer;
  Duration saveLocation = Duration(seconds: 2);
  Duration transmitLocation = Duration(seconds: 10);
  DatabaseLocations databaseLocations = DatabaseLocations.instance;



  RoutingCoordinator(this.routingController, this.predictionController,
      this.subscriptionController, this.locationController);


  void saveCurrentLocation(Timer timer) async{
    var location = LocationPlus();
    location.latitude = locationController.currentLocation.latitude;
    location.longitude = locationController.currentLocation.longitude;
    location.nextLsaId = predictionController.nextLSA.id;
    location.nextSgName = predictionController.nextSG.sgName;
    location.accuracy = locationController.currentLocation.accuracy;
    location.altitude = locationController.currentLocation.altitude;
    location.speed = locationController.currentLocation.speed;
    location.distanceNextSG = predictionController.nextSG.distance.toInt();
    location.recommendedSpeedKmh = (predictionController.currentPhase.getRecommendedSpeed()*3.6).toInt();
    location.differenceSpeedKmh = (location.speed*3.6 - location.recommendedSpeedKmh).abs();
    location.isGreen = predictionController.currentPhase.isGreen;
    location.isSimulation = await SettingService.instance.isSimulator;
    location.nextInstructionText = predictionController.nextInstruction.info;;
    location.nextSg = predictionController.nextSG.toString();
    location.nextGhNode = predictionController.nextGHNode.id;


    databaseLocations.insertLocation(location);



  }

  void transmitLocations(Timer timer) async{
    var list = await databaseLocations.getLocationsToTransmit();
    for(var loc in list){
      await databaseLocations.markAsTransmitted(loc.id);
    }
    await databaseLocations.deleteAllTransmittedLocations();

  }


  void run() {
    if(_saveLocationTimer == null && _transmitLocationTimer == null){
      _saveLocationTimer = Timer.periodic(saveLocation, saveCurrentLocation);
      _transmitLocationTimer = Timer.periodic(transmitLocation, transmitLocations);
    }

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
