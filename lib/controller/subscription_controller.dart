import 'package:bike_now_flutter/models/subscription.dart';
import 'package:bike_now_flutter/websocket/web_socket_service.dart';
import 'package:bike_now_flutter/websocket/websocket_commands.dart';
import 'package:bike_now_flutter/configuration.dart';
import 'package:bike_now_flutter/models/sg.dart';

class SubscriptionController {
  List<Subscription> subscriptions = [];
  WebSocketService webSocketService = WebSocketService.instance;

  void update() {
    webSocketService.sendCommand(
        UpdateSubscription(subscriptions, Configuration.sessionUUID));
  }

  void subscribe(SG sg) {
    Subscription subscription = sg.makeSubscription();
    if (!subscriptions.contains(subscription)) {
      subscriptions.add(subscription);
      update();
    }
  }

  void unsubscribe(SG sg) {
    subscriptions.remove(sg.makeSubscription());
    update();
  }

  void reset() {
    subscriptions = [];
    update();
  }
}
