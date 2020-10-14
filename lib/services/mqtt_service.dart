import 'dart:async';
import 'package:bikenow/config/logger.dart';
import 'package:bikenow/models/message.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  static const BROKER_URL = "bikenow.vkw.tu-dresden.de";
  static const PORT = 20050;
  static const USERNAME = 'bikenow-user';
  static const PASSWORD = 'mRMLa8jcgczZF7Ev';

  List<String> topics;

  Logger log = new Logger('MQTTService');

  MqttServerClient _client;

  StreamController<Message> messageStreamController =
      new StreamController<Message>();

  MqttService(String clientId, List<String> topics) {
    _client = MqttServerClient(BROKER_URL, clientId)
      ..port = PORT
      ..onDisconnected = _onDisconnected
      ..onConnected = _onConnected
      ..logging(on: false)
      ..connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean() // Non persistent session for testing
          .withWillQos(MqttQos.exactlyOnce);

    _connect();

    this.topics = topics;
  }

  void _connect() async {
    try {
      await _client.connect(USERNAME, PASSWORD);
    } on Exception catch (e) {
      log.e(e);
      _client.disconnect();
    }

    _client.updates.listen((List<MqttReceivedMessage<MqttMessage>> m) {
      final MqttPublishMessage binaryMessage = m[0].payload;

      final String textMessage = MqttPublishPayload.bytesToStringAsString(
          binaryMessage.payload.message);

      final Message message = Message(topic: m[0].topic, payload: textMessage);

      messageStreamController.add(message);

      // log.i('-> MESSAGE ${message.topic}');
    });
  }

  void _onDisconnected() {
    log.w('Client disconnected!');
  }

  void _onConnected() {
    log.i('Connection to MQTT Broker ($BROKER_URL) successful');

    topics.forEach((topic) {
      this.subscribe(topic);
    });
  }

  void subscribe(String topic) {
    if (_client.connectionStatus.state != MqttConnectionState.connected) {
      _connect();
    }
    _client.subscribe(topic, MqttQos.atLeastOnce);
    log.i('SUBSCRIBE to $topic ');
  }

  void publish(Message message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message.payload);
    _client.publishMessage(message.topic, MqttQos.exactlyOnce, builder.payload);

    // log.i('<- PUBLISH ${message.topic} ');
  }

  void unsubscribe(String topic) {
    _client.unsubscribe(topic);
    // log.i('⨯ UNSUBSCRIBE $topic ');
  }

  void dispose() {
    messageStreamController.close();
  }
}
