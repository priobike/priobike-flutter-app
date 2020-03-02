import 'dart:async';

import 'package:bikenow/alogrithms/geo_algorithms.dart';
import 'package:bikenow/alogrithms/prediction_algorithms.dart';
import 'package:bikenow/config/config.dart';
import 'package:bikenow/config/logger.dart';
import 'package:bikenow/models/api/api_prediction.dart';
import 'package:bikenow/models/api/api_sg.dart';
import 'package:bikenow/models/recommendation.dart';
import 'package:bikenow/services/gateway_status_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock/wakelock.dart';

class RecommendationService {
  Logger log = new Logger('RecommendationService');
  Position _position;
  Map<String, ApiPrediction> _predictions = new Map();
  ApiSg _nextSg;

  Timer timer;

  GatewayStatusService gatewayStatusService;

  StreamController<Recommendation> recommendationStreamController =
      new StreamController<Recommendation>.broadcast();

  RecommendationService({
    GatewayStatusService gatewayStatusService,
    Stream<ApiSg> nextSgStream,
    Stream<Map<String, ApiPrediction>> predictionStream,
    Stream<Position> positionStream,
  }) {
    nextSgStream.listen((nextSg) {
      _nextSg = nextSg;
    });

    predictionStream.listen((newPredictions) {
      _predictions = newPredictions;
    });

    positionStream.listen((newPosition) {
      _position = newPosition;
    });

    this.gatewayStatusService = gatewayStatusService;
  }

  startRecommendation() {
    Wakelock.enable();
    log.i('Start calculating recommendations');
    if (timer == null) {
      timer = Timer.periodic(Duration(seconds: Config.timerInterval), (_) {
        _calculateRecommendation();
      });
    }
  }

  _calculateRecommendation() {
    if (_predictions == null)
      log.w('!!! WARNING: No Prediction for SG ${_nextSg.mqtt} !!!');
    if (_nextSg == null) log.w('!!! WARNING: No Next SG !!!');
    if (_position == null) log.w('!!! WARNING: No Position !!!');

    if (_predictions != null && _nextSg != null && _position != null) {
      Stopwatch stopwatch = new Stopwatch()..start();
      ApiPrediction predictionForSg = _predictions[_nextSg.mqtt];

      log.i('Nächste SG ist ${_nextSg.mqtt}');

      if (predictionForSg == null)
        log.w('!!! WARNING: Prediction for SG is null !!!');

      if (predictionForSg != null) {
        DateTime startTime = DateTime.parse(predictionForSg.startTime);
        int t = DateTime.now().difference(startTime).inSeconds -
            gatewayStatusService.timeDifference;

        print(predictionForSg.startTime);
        print(startTime);
        print(DateTime.now());

        bool isGreen = PredictionAlgorithm.isGreen(
          predictionForSg.value[t],
          predictionForSg.greentimeThreshold,
        );

        int secondsToPhaseChange = PredictionAlgorithm.secondsToPhaseChange(
          predictionForSg.value,
          isGreen,
          predictionForSg.greentimeThreshold,
          t,
        );

        double distance = GeoAlgorithm.distanceBetween(
          _position.latitude,
          _position.longitude,
          _nextSg.lat,
          _nextSg.lon,
        );

        Recommendation recommendation;

        try {
          double speedRecommendation = PredictionAlgorithm.speedRecommendation(
            predictionForSg.value,
            distance,
            _position.speed,
            predictionForSg.greentimeThreshold,
            t,
          );

          recommendation = new Recommendation(
            _nextSg.mqtt,
            _predictions[_nextSg.mqtt].timestamp,
            isGreen,
            distance,
            secondsToPhaseChange,
            speedRecommendation,
            null,
          );
        } catch (e, stack) {
          log.e(e);
          log.e(stack);

          recommendation = new Recommendation(
            _nextSg.mqtt,
            _predictions[_nextSg.mqtt].timestamp,
            isGreen,
            distance,
            secondsToPhaseChange,
            0,
            e.toString(),
          );
        }

        recommendationStreamController.add(recommendation);
        log.i(
            '(t:${timer.tick}) Calculated recommendation in ${stopwatch.elapsed.inMicroseconds / 1000}ms');
      }
    }
  }

  endRecommendation() {
    log.i("Stop calculating recommendations");
    Wakelock.disable();
    timer.cancel();
    timer = null;
  }

  dispose() {
    recommendationStreamController.close();
  }
}
