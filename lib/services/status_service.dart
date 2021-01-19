import 'package:priobike/config/api.dart';
import 'package:priobike/config/config.dart';
import 'package:priobike/config/logger.dart';
import 'package:priobike/models/api/api_pilotstrecken.dart';
import 'package:priobike/models/api/api_status.dart';
import 'package:flutter/foundation.dart';

class StatusService with ChangeNotifier {
  Logger log = new Logger('GatewayStatus');

  ApiStatus answer = new ApiStatus();

  ApiPilotstrecken pilotstrecken;

  int timeDifference;

  bool loading = true;

  StatusService() {
    getStatus();
  }

  getStatus() async {
    log.i('Connect to Gateway (${Config.GATEWAY_URL}) ...');

    try {
      answer = await Api.getStatus();
      pilotstrecken = await Api.getPilotstrecken();
    } catch (e) {}

    loading = false;

    notifyListeners();

    log.i('Gateway Status OK');
  }
}
