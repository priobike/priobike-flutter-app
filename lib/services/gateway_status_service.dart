import 'package:bikenow/config/api.dart';
import 'package:bikenow/config/logger.dart';
import 'package:bikenow/models/api/api_pilotstrecken.dart';
import 'package:bikenow/models/api/api_status.dart';
import 'package:flutter/foundation.dart';

class GatewayStatusService with ChangeNotifier {
  Logger log = new Logger('GatewayStatus');

  ApiStatus answer = new ApiStatus();
  
  ApiPilotstrecken pilotstrecken;

  int timeDifference;

  bool loading = true;

  GatewayStatusService() {
    getStatus();
  }

  getStatus() async {
    log.i('Connect to Gateway (${Api.HOST}) ...');

    // TODO: handle connection errors
    try {
      answer = await Api.getStatus();
      pilotstrecken = await Api.getPilotstrecken();
    } catch (e) {}

    timeDifference = DateTime.now()
        .difference(DateTime.parse(answer.gatewayTime).toLocal())
        .inSeconds;

    loading = false;

    notifyListeners();

    log.i('Gateway Status OK');
  }
}
