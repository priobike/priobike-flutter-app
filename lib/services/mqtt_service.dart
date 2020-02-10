import 'dart:async';
import 'package:bikenow/config/logger.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MqttService {
  static const BROKER_URL = "ws://bikenow.vkw.tu-dresden.de";
  static const PORT = 20051;
  static const USERNAME = 'bikenow-user';
  static const PASSWORD = 'mRMLa8jcgczZF7Ev';
  static const CLIENT_IDENTIFIER = 'Android';

  Logger log = new Logger('MQTTService');

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
      log.e(e);
      _client.disconnect();
    }

    _client.updates.listen((List<MqttReceivedMessage<MqttMessage>> data) {
      final String topic = data[0].topic;
      final MqttPublishMessage binaryMessage = data[0].payload;

      final String textMessage = MqttPublishPayload.bytesToStringAsString(
          binaryMessage.payload.message);

      messageStreamController.add(textMessage);

      log.i('✉ New message for $topic');
    });
  }

  void _onDisconnected() {
    log.w('Client disconnected!');
  }

  void _onConnected() {
    log.i('Connection to MQTT Broker ($BROKER_URL) successful');
  }

  void subscribe(String topic) {
    if (_client.connectionStatus.state != MqttConnectionState.connected) {
      _connect();
    }
    _client.subscribe(topic, MqttQos.atLeastOnce);
    log.i('⬅ Subscribed to $topic ');
  }

  void unsubscribe(String topic) {
    _client.unsubscribe(topic);
    log.i('⨯ Unsubscribed from $topic ');
  }

  void dispose() {
    messageStreamController.close();
  }
}
