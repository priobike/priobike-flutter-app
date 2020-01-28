import 'dart:async';

import 'package:bikenow/config/config.dart';
import 'package:bikenow/models/api/api_prediction.dart';
import 'package:bikenow/models/api/api_route.dart';
import 'package:bikenow/models/vorhersage.dart';

class VorhersageService {
  Map<String, ApiPrediction> _predictions = new Map();
  ApiRoute _route;

  Timer timer;

  StreamController<List<Vorhersage>> vorhersageStreamController =
      new StreamController<List<Vorhersage>>.broadcast();

  VorhersageService(
      {Stream<ApiRoute> routeStream,
      Stream<Map<String, ApiPrediction>> predictionStream}) {
    routeStream.listen((newRoute) {
      _route = newRoute;
    });

    predictionStream.listen((newPredictions) {
      _predictions = newPredictions;
    });
  }

  startVorhersage() {
    timer = new Timer.periodic(Duration(seconds: Config.timerInterval), (_) {
      calculateVorhersage();
    });
  }

  calculateVorhersage() {
    if (_predictions != null && _route != null) {
      List<Vorhersage> vorhersageListe = new List<Vorhersage>();

      _route.sg.forEach((sg) {
        Vorhersage vorhersage = new Vorhersage(sg.mqtt, 123);

        vorhersageListe.add(vorhersage);
      });

      print(vorhersageListe.length);

      vorhersageStreamController.add(vorhersageListe);
    }
  }

  endVorhersage() {
    timer.cancel();
  }

  dispose() {
    vorhersageStreamController.close();
  }
}
