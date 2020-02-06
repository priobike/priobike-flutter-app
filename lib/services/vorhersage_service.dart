import 'dart:async';

import 'package:bikenow/alogrithms/geo_algorithms.dart';
import 'package:bikenow/alogrithms/prediction_algorithms.dart';
import 'package:bikenow/config/config.dart';
import 'package:bikenow/models/api/api_prediction.dart';
import 'package:bikenow/models/api/api_route.dart';
import 'package:bikenow/models/vorhersage.dart';
import 'package:bikenow/services/gateway_status_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock/wakelock.dart';

class VorhersageService {
  Position _position;
  Map<String, ApiPrediction> _predictions = new Map();
  ApiRoute _route;

  Timer timer;

  GatewayStatusService gatewayStatusService;

  StreamController<List<Vorhersage>> vorhersageStreamController =
      new StreamController<List<Vorhersage>>.broadcast();

  VorhersageService(
      {GatewayStatusService gatewayStatusService,
      Stream<ApiRoute> routeStream,
      Stream<Map<String, ApiPrediction>> predictionStream,
      Stream<Position> locationStream}) {
    routeStream.listen((newRoute) {
      _route = newRoute;
    });

    predictionStream.listen((newPredictions) {
      _predictions = newPredictions;
    });

    locationStream.listen((newPosition) {
      _position = newPosition;
    });

    this.gatewayStatusService = gatewayStatusService;
  }

  startVorhersage() {
    Wakelock.enable();
    print('=> start vorhersage');
    if (timer == null) {
      timer = Timer.periodic(Duration(seconds: Config.timerInterval), (_) {
        _calculateVorhersage();
      });
    }
  }

  _calculateVorhersage() {
    Stopwatch stopwatch = new Stopwatch()..start();
    if (_predictions != null && _route != null && _position != null) {
      List<Vorhersage> vorhersageListe = new List<Vorhersage>();

      _route.sg.forEach((sg) {
        ApiPrediction predictionForSg = _predictions[sg.mqtt];

        if (predictionForSg != null) {
          DateTime startTime = DateTime.parse(predictionForSg.startTime);
          int t = DateTime.now().difference(startTime).inSeconds -
              gatewayStatusService.timeDifference;

          bool isGreen = PredictionAlgorithm.isGreen(
              predictionForSg.value[t], predictionForSg.greentimeThreshold);

          int secondsToPhaseChange = PredictionAlgorithm.secondsToPhaseChange(
              predictionForSg.value,
              isGreen,
              predictionForSg.greentimeThreshold,
              t);

          double distance = GeoAlgorithm.distanceBetween(
              _position.latitude, _position.longitude, sg.lat, sg.lon);

          Vorhersage vorhersage = new Vorhersage(
              sg.mqtt,
              _predictions[sg.mqtt].timestamp,
              isGreen,
              distance.round(),
              secondsToPhaseChange);

          vorhersageListe.add(vorhersage);
        } else {
          print('!!! WARNING: No Prediction for SG ${sg.mqtt} !!!');
        }
      });

      print(
          '[${timer.tick}] calculated vorhersagen in ${stopwatch.elapsed.inMicroseconds / 1000}ms');

      // add complete liste to stream and UI
      vorhersageStreamController.add(vorhersageListe);
    }
  }

  endVorhersage() {
    print("=> end vorhersage");
    Wakelock.disable();
    timer.cancel();
    timer = null;
  }

  dispose() {
    vorhersageStreamController.close();
  }
}
