import 'package:bikenow/services/prediction_service.dart';
import 'package:bikenow/services/routing_service.dart';
import 'package:flutter/foundation.dart';

class MainService {
  bool loading = false;

  RoutingService routingService;
  PredictionService predictionService;

  MainService() {
    routingService = new RoutingService();

    predictionService = new PredictionService(
      routeStream: routingService.routeStreamController.stream,
    );

    predictionService.predictionStreamController.stream.listen((prediction) {
      print(prediction);
    });
  }

  // startTimer() {
  // if (timer == null) {
  //   timer =
  //       Timer.periodic(new Duration(seconds: Config.timerInterval), (timer) {
  //     this.predictions.values.forEach((prediction) {
  //       // prediction.calculateIsGreen(timer.tick);
  //     });

  //     print('notify Listeners (t:${timer.tick})');
  //     notifyListeners();
  //   });
  // }
  // }

  // endTimer() {
  //   timer.cancel();
  //   timer = null;
  // }

}
