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

  bool loading = true;

  StatusService() {
    getStatus();
  }

  getStatus() async {
    loading = false;
    notifyListeners();
  }
}
