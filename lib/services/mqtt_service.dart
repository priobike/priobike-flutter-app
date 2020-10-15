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
    _client = MqttServerClient.withPort(BROKER_URL, clientId, PORT)
      ..autoReconnect = true
      ..onDisconnected = _onDisconnected
      ..onConnected = _onConnected
      ..onAutoReconnect = _onAutoReconnect
      ..onAutoReconnected = _onAutoReconnected
      ..resubscribeOnAutoReconnect = true
      ..keepAlivePeriod = 30
      ..logging(on: false)
      ..connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .withWillQos(MqttQos.exactlyOnce);

    this.topics = topics;

    _client.connect(USERNAME, PASSWORD);
  }

  void _onConnected() {
    log.i('Connection to MQTT Broker ($BROKER_URL) successful');

    topics.forEach((topic) {
      this.subscribe(topic);
    });

    _client.updates.listen((List<MqttReceivedMessage<MqttMessage>> m) {
      final MqttPublishMessage binaryMessage = m[0].payload;

      final String textMessage = MqttPublishPayload.bytesToStringAsString(
          binaryMessage.payload.message);

      final Message message = Message(topic: m[0].topic, payload: textMessage);

      messageStreamController.add(message);
    });
  }

  void subscribe(String topic) {
    if (_client.connectionStatus.state != MqttConnectionState.connected) {
      _client.doAutoReconnect();
    }
    _client.subscribe(topic, MqttQos.atLeastOnce);
    log.i('SUBSCRIBE to $topic ');
  }

  void publish(Message message) {
    if (_client.connectionStatus.state != MqttConnectionState.connected) {
      _client.doAutoReconnect();
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString(message.payload);
    _client.publishMessage(message.topic, MqttQos.exactlyOnce, builder.payload);
  }

  void unsubscribe(String topic) {
    _client.unsubscribe(topic);
    log.i('UNSUBSCRIBE $topic ');
  }

  void _onDisconnected() {
    log.w('Client disconnected!');
  }

  void _onAutoReconnect() {
    log.w('try Reconnection to Broker');
  }

  void _onAutoReconnected() {
    log.i('Client reconnected to Broker');
  }

  void dispose() {
    messageStreamController.close();
  }
}
