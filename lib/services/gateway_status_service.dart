import 'package:bikenow/config/api.dart';
import 'package:bikenow/models/gateway_status.dart';
import 'package:flutter/foundation.dart';

class GatewayStatusService with ChangeNotifier {
  GatewayStatus answer = new GatewayStatus();
  bool loading = false;

  GatewayStatusService() {
    getStatus();
  }

  getStatus() async {
    loading = true;
    notifyListeners();

    answer = await Api.getStatus();
    loading = false;
    notifyListeners();
  }
}
