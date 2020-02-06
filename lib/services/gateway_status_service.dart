import 'package:bikenow/config/api.dart';
import 'package:bikenow/models/api/api_status.dart';
import 'package:flutter/foundation.dart';

class GatewayStatusService with ChangeNotifier {
  ApiStatus answer = new ApiStatus();

  int timeDifference;

  bool loading = true;

  GatewayStatusService() {
    getStatus();
  }

  getStatus() async {
    print('Checke Gateway Status...');

    answer = await Api.getStatus();

    timeDifference = DateTime.now()
        .difference(DateTime.parse(answer.gatewayTime).toLocal())
        .inSeconds;

    loading = false;

    notifyListeners();
    print('Gateway erreichbar :)');
  }
}
