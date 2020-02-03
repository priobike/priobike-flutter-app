import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';

class MqttService {
  static const BROKER_URL = "ws://vkwvlprad.vkw.tu-dresden.de";
  static const PORT = 20051;
  static const USERNAME = 'bikenow';
  static const PASSWORD = 'mqtt-test';
  static const CLIENT_IDENTIFIER = 'Android';

  MqttClient _client;

  StreamController<String> messageStreamController =
      new StreamController<String>();

  MqttService() {
    final MqttConnectMessage connectMessage = MqttConnectMessage()
        .withClientIdentifier(CLIENT_IDENTIFIER)
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.exactlyOnce);

    _client = MqttClient(BROKER_URL, CLIENT_IDENTIFIER)
      ..useWebSocket = true
      ..port = PORT
      ..onDisconnected = _onDisconnected
      ..onConnected = _onConnected
      ..logging(on: false)
      ..connectionMessage = connectMessage;

    _connect();
  }

  void _connect() async {
    try {
      await _client.connect(USERNAME, PASSWORD);
    } on Exception catch (e) {
      print(e);
      _client.disconnect();
    }

    _client.updates.listen((List<MqttReceivedMessage<MqttMessage>> data) {
      final String topic = data[0].topic;
      final MqttPublishMessage binaryMessage = data[0].payload;

      final String textMessage = MqttPublishPayload.bytesToStringAsString(
          binaryMessage.payload.message);

      messageStreamController.add(textMessage);

      print('MQTT: ## new message for $topic ##');
    });
  }

  void _onDisconnected() {
    print('MQTT: ## client disconnected ##');
  }

  void _onConnected() {
    print('MQTT: ## connection to broker successfull ##');
  }

  void subscribe(String topic) {
    if (_client.connectionStatus.state == MqttConnectionState.disconnected) {
      _connect();
    }
    _client.subscribe(topic, MqttQos.atLeastOnce);
    print('MQTT: ## subscribed to $topic ##');
  }

  void unsubscribe(String topic) {
    _client.unsubscribe(topic);
    print('MQTT: ## unsubscribed from $topic ##');
  }

  void dispose() {
    messageStreamController.close();
  }
}
