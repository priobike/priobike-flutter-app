import 'package:mqtt_client/mqtt_client.dart';

class MqttService {
  MqttClient client;

  static const BROKER_URL = "ws://vkwvlprad.vkw.tu-dresden.de";
  static const PORT = 20051;

  static const USERNAME = 'bikenow';
  static const PASSWORD = 'mqtt-test';

  static const CLIENT_IDENTIFIER = 'Android';

  MqttService() {
    final MqttConnectMessage connectMessage = MqttConnectMessage()
        .withClientIdentifier(CLIENT_IDENTIFIER)
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.exactlyOnce);

    client = MqttClient(BROKER_URL, CLIENT_IDENTIFIER)
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
      await client.connect(USERNAME, PASSWORD);
    } on Exception catch (e) {
      print(e);
      client.disconnect();
    }

    const String topic = 'prediction/420/#';
    client.subscribe(topic, MqttQos.atMostOnce);

    client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload;
      final String pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print('MQTT-MESSAGE: topic: <${c[0].topic}>, payload: <-- $pt -->');
      print('');
    });
  }

  void _onDisconnected() {
    print('MQTT: ##Client disconnected##');
  }

  void _onConnected() {
    print('MQTT: ##client connection was successful##');
  }
}
