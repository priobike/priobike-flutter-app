import 'dart:async';

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
    print('start vorhersage');
    if (timer == null) {
      timer = Timer.periodic(Duration(seconds: Config.timerInterval), (_) {
        _calculateVorhersage();
      });
    }
  }

  _calculateVorhersage() {
    print('calculate vorhersage');
    if (_predictions != null && _route != null && _position != null) {
      List<Vorhersage> vorhersageListe = new List<Vorhersage>();

      // TODO: Remove sublist filter
      _route.sg.sublist(1, 10).forEach((sg) async {
        ApiPrediction predictionForSg = _predictions[sg.mqtt];

        DateTime time = DateTime.parse(predictionForSg.timestamp);
        DateTime now = new DateTime.now();

        int diff = now.difference(time).inSeconds;

        List<String> values = predictionForSg.value.split(',');

        bool isGreen = (double.parse(values[diff]) >=
            double.parse(predictionForSg.greentimeTreshold));

        Vorhersage vorhersage;

        double distance = await Geolocator().distanceBetween(
            _position.latitude, _position.longitude, sg.lat, sg.lon);

        vorhersage = new Vorhersage(sg.mqtt, _predictions[sg.mqtt].timestamp,
            isGreen, distance.round());

        vorhersageListe.add(vorhersage);
      });

      print(timer.tick);

      vorhersageStreamController.add(vorhersageListe);
    }
  }

  endVorhersage() {
    Wakelock.disable();
    timer.cancel();
  }

  dispose() {
    vorhersageStreamController.close();
  }
}
