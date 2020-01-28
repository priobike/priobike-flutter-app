import 'package:bikenow/config/api.dart';
import 'package:bikenow/models/api/api_status.dart';
import 'package:flutter/foundation.dart';

class GatewayStatusService with ChangeNotifier {
  ApiStatus answer = new ApiStatus();
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
