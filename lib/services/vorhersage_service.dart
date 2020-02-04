import 'dart:async';

import 'package:bikenow/alogrithms/geo.dart';
import 'package:bikenow/config/config.dart';
import 'package:bikenow/models/api/api_prediction.dart';
import 'package:bikenow/models/api/api_route.dart';
import 'package:bikenow/models/vorhersage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock/wakelock.dart';

class VorhersageService {
  Position _position;
  Map<String, ApiPrediction> _predictions = new Map();
  ApiRoute _route;

  Timer timer;

  StreamController<List<Vorhersage>> vorhersageStreamController =
      new StreamController<List<Vorhersage>>.broadcast();

  VorhersageService(
      {Stream<ApiRoute> routeStream,
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
          // calculate difference from now to prediction start
          DateTime startTime = DateTime.parse(predictionForSg.startTime);
          int diff = DateTime.now().difference(startTime).inSeconds;

          // check the current phase
          bool isGreen = (predictionForSg.value[diff] >=
              predictionForSg.greentimeThreshold);

          // count seconds to next phase change
          int secondsToPhaseChange = 0;
          for (var i = diff; i < predictionForSg.value.length; i++) {
            bool green =
                predictionForSg.value[i] >= predictionForSg.greentimeThreshold;

            if ((isGreen && !green) || (!isGreen && green)) {
              break;
            }

            secondsToPhaseChange++;
          }

          // calculate distance from position to sg
          double distance = Geo.distanceBetween(
              _position.latitude, _position.longitude, sg.lat, sg.lon);

          // create new vorhersage and add to a list
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
          '[${timer.tick}] calculated vorhersagen in ${stopwatch.elapsed.inMilliseconds}ms');

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
