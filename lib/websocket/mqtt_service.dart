import 'dart:async';
import 'package:web_socket_channel/io.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';

import 'package:bike_now_flutter/helper/configuration.dart';
import 'package:bike_now_flutter/websocket/websocket_commands.dart';
import 'package:bike_now_flutter/server_response/websocket_response.dart';
import 'package:bike_now_flutter/websocket/web_socket_method.dart';


class MqttService implements MqttDelegate {
  String broker           = "ws://vkwvlprad.vkw.tu-dresden.de";
  int port                = 20051;
  String username         = 'bikenow';
  String passwd           = 'mqtt-test';
  String clientIdentifier = 'android';

  MqttDelegate delegate;


  MqttClient client;
  MqttConnectionState connectionState;
  StreamSubscription subscription;


  void _connect() async {
    client = MqttClient(broker, '');
    client.useWebSocket = true;
    client.port = port;
    client.logging(on: true);
    client.keepAlivePeriod = 30;
    client.onDisconnected = _onDisconnected;

    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .startClean() // Non persistent session for testing
        .keepAliveFor(30)
        .withWillQos(MqttQos.exactlyOnce);
    client.connectionMessage = connMess;

    try {
      await client.connect(username, passwd);
    } catch (e) {
      print(e);
      _disconnect();
    }

    if (client.connectionState == MqttConnectionState.connected) {
        connectionState = client.connectionState;
    } else {
      _disconnect();
    }
    subscription = client.updates.listen(_onMessage);
    _subscribeToTopic('prediction/420/#');
  }

  void _subscribeToTopic(String topic) {
    if (connectionState == MqttConnectionState.connected) {
      client.subscribe(topic, MqttQos.exactlyOnce);
    }
  }

  void _onMessage(List<MqttReceivedMessage> event) {
    final MqttPublishMessage recMess =
    event[0].payload as MqttPublishMessage;
    final String message =
    MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    mqttDidReceiveMessage(message);
  }

  void _disconnect() {
    print('[MQTT client] _disconnect()');
    client.disconnect();
    _onDisconnected();
  }

  void _onDisconnected() {
    print('[MQTT client] _onDisconnected');
      //topics.clear();
      connectionState = client.connectionState;
      client = null;
      subscription.cancel();
      subscription = null;
    print('[MQTT client] MQTT client disconnected');
  }

  final Logger log = new Logger('MQTT');

  MqttService._privateConstructor() {
    _connect();
  }
  static final MqttService instance =
  MqttService._privateConstructor();

  @override
  void mqttDidReceiveMessage(String msg) {
    delegate.mqttDidReceiveMessage(msg);
  }
}

abstract class MqttDelegate {
  void mqttDidReceiveMessage(String msg);
}
