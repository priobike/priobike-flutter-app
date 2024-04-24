import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/interfaces/prediction.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:typed_data/typed_buffers.dart';

Logger log = Logger("MQTT");

MqttClient getMQTTClient(String logName, String path, int port) {
  final settings = getIt<Settings>();
  if (settings.usePredictionsFromRecordedTrack) {
    return initMockClient(logName, path, port);
  } else {
    return initClient(logName, path, port);
  }
}

/// Init the prediction MQTT client.
MqttClient initClient(String logName, String path, int port) {
  final clientId = 'priobike-app-${UniqueKey().toString()}'; // Random client ID.
  final client = MqttServerClient(path, clientId);
  client.logging(on: false);
  client.keepAlivePeriod = 30;
  client.secure = false;
  client.port = port;
  client.autoReconnect = true;
  client.resubscribeOnAutoReconnect = true;
  client.onDisconnected = () => log.i("🛜❌ $logName MQTT client disconnected");
  client.onConnected = () => log.i("🛜✅ $logName MQTT client connected");
  client.onSubscribed = (topic) => log.i("🫡✅ $logName MQTT client subscribed to $topic");
  client.onUnsubscribed = (topic) => log.i("🫡❌ $logName MQTT client unsubscribed from $topic");
  client.onAutoReconnect = () => log.i("🛜🔁 $logName MQTT client auto reconnect");
  client.onAutoReconnected = () => log.i("🛜🔁✅ $logName MQTT client auto reconnected");
  client.setProtocolV311(); // Default Mosquitto protocol
  client.connectionMessage =
      MqttConnectMessage().withClientIdentifier(client.clientIdentifier).startClean().withWillQos(MqttQos.atMostOnce);
  return client;
}

/// Init the prediction MQTT client.
MqttClient initMockClient(String logName, String path, int port) {
  final clientId = 'priobike-app-${UniqueKey().toString()}'; // Random client ID.
  final client = MockMqttServerClient(path, clientId, type: logName);
  client.logging(on: false);
  client.keepAlivePeriod = 30;
  client.port = port;
  client.autoReconnect = true;
  client.resubscribeOnAutoReconnect = true;
  client.onDisconnected = () => log.i("🛜❌ $logName MQTT client disconnected");
  client.onConnected = () => log.i("🛜✅ $logName MQTT client connected");
  client.onSubscribed = (topic) => log.i("🫡✅ $logName MQTT client subscribed to $topic");
  client.onUnsubscribed = (topic) => log.i("🫡❌ $logName MQTT client unsubscribed from $topic");
  client.onAutoReconnect = () => log.i("🛜🔁 $logName MQTT client auto reconnect");
  client.onAutoReconnected = () => log.i("🛜🔁✅ $logName MQTT client auto reconnected");
  client.setProtocolV311(); // Default Mosquitto protocol
  client.connectionMessage =
      MqttConnectMessage().withClientIdentifier(client.clientIdentifier).startClean().withWillQos(MqttQos.atMostOnce);
  return client;
}

class MockMqttServerClient extends MockMqttClient {
  MockMqttServerClient(super.server, super.clientIdentifier, {required super.type});
}

class MockMqttClient extends MqttClient {
  Logger log = Logger("MQTT-Client");

  bool initSetupCompleted = false;

  DateTime? localStartTime;
  DateTime? trackStartTime;

  /// Either 'Predictor' or 'PredictionService'.
  String type;

  MockMqttClient(super.server, super.clientIdentifier, {required this.type});

  Map<String, List<PredictionServicePrediction>> psPredictionsBySgId = {};
  Map<String, List<PredictorPrediction>> pPredictionsBySgId = {};

  Map<String, List<Timer>> newPredictionTimersBySgId = {};

  final StreamController<List<MqttReceivedMessage<MqttMessage>>> _updates =
      StreamController<List<MqttReceivedMessage<MqttMessage>>>.broadcast(sync: true);

  @override
  Stream<List<MqttReceivedMessage<MqttMessage>>>? get updates => _updates.stream;

  void loadPredictionsP(dynamic metadata) {
    if (pPredictionsBySgId.isNotEmpty) return;

    final predictions = metadata["predictorPredictions"];
    for (final prediction in predictions) {
      final pPrediction = PredictorPrediction.fromJson(prediction);
      if (pPredictionsBySgId.containsKey(pPrediction.thingName)) {
        pPredictionsBySgId[pPrediction.thingName]!.add(pPrediction);
      } else {
        pPredictionsBySgId[pPrediction.thingName] = [pPrediction];
      }
    }
  }

  void loadPredictionsPS(dynamic metadata) {
    if (psPredictionsBySgId.isNotEmpty) return;

    final predictions = metadata["predictionServicePredictions"];
    for (final prediction in predictions) {
      final psPrediction = PredictionServicePrediction.fromJson(prediction);
      if (psPredictionsBySgId.containsKey(psPrediction.signalGroupId)) {
        psPredictionsBySgId[psPrediction.signalGroupId]!.add(psPrediction);
      } else {
        psPredictionsBySgId[psPrediction.signalGroupId] = [psPrediction];
      }
    }
  }

  @override
  Future<MqttClientConnectionStatus?> connect([String? username, String? password]) async {
    super.connectionStatus?.state = MqttConnectionState.connected;
    if (initSetupCompleted) return super.connectionStatus;

    String filecontents = await rootBundle.loadString("assets/tracks/hamburg/users/track.json");
    dynamic json = jsonDecode(filecontents);
    final metadata = json["metadata"];
    if (type == "PredictionService") {
      loadPredictionsPS(metadata);
    } else if (type == "Predictor") {
      loadPredictionsP(metadata);
    } else {
      throw Exception("Unknown type $type");
    }

    trackStartTime ??= DateTime.fromMillisecondsSinceEpoch(metadata["startTime"] + (0 * 1000));
    localStartTime ??= DateTime.now();
    initSetupCompleted = true;
    return super.connectionStatus;
  }

  @override
  void unsubscribe(String topic, {expectAcknowledge = false}) {
    topic = topic.replaceAll("hamburg/", "");
    if (!newPredictionTimersBySgId.containsKey(topic)) return;
    for (final timer in newPredictionTimersBySgId[topic]!) {
      timer.cancel();
    }
  }

  MqttPublishMessage createMessageFromPrediction(Map<String, dynamic> prediction) {
    final data = jsonEncode(prediction);
    final bytes = utf8.encode(data);
    final uint8Buffer = Uint8Buffer();
    uint8Buffer.addAll(bytes);
    final header = MqttHeader();
    header.qos = MqttQos.atLeastOnce;
    header.retain = true;
    header.duplicate = false;
    final payload = MqttPublishPayload();
    payload.message = uint8Buffer;
    final message = MqttPublishMessage();
    message.header = header;
    message.payload = payload;
    return message;
  }

  PredictionServicePrediction psPredictionWithNewTime(DateTime startTime, PredictionServicePrediction psPrediction) {
    final json = psPrediction.toJson();
    json["startTime"] = startTime.toIso8601String();
    return PredictionServicePrediction.fromJson(json);
  }

  PredictorPrediction pPredictionWithNewTime(DateTime referenceTime, PredictorPrediction pPrediction) {
    final json = pPrediction.toJson();
    json["referenceTime"] = referenceTime.toIso8601String();
    return PredictorPrediction.fromJson(json);
  }

  @override
  Subscription? subscribe(String topic, MqttQos qosLevel) {
    topic = topic.replaceAll("hamburg/", "");

    if (connectionStatus!.state != MqttConnectionState.connected) {
      throw ConnectionException(connectionHandler?.connectionStatus.state);
    }
    log.i("Setting up mock predictions to $topic");
    final currentTime = DateTime.now();
    final secondsDriven = currentTime.difference(localStartTime!).inSeconds;
    final trackTime = trackStartTime!.add(Duration(seconds: secondsDriven));
    log.i(
        "Current Time: $currentTime - Local start time: $localStartTime - Track start time: $trackStartTime - Seconds driven: $secondsDriven - Track time: $trackTime");

    final predictionsBySgId = type == "PredictionService" ? psPredictionsBySgId : pPredictionsBySgId;
    if (!predictionsBySgId.containsKey(topic)) {
      return null;
    }
    final predictions = predictionsBySgId[topic]!;
    Prediction? initPrediction;
    for (final prediction in predictions) {
      dynamic p = prediction;
      final referenceTime = type == "PredictionService" ? p.startTime : p.referenceTime;
      final timeDiff = referenceTime.difference(trackTime).inSeconds;
      if (timeDiff <= 0) {
        initPrediction = prediction;
        continue;
      }
      if (timeDiff >= 0) {
        if (initPrediction != null) {
          dynamic initP = initPrediction;
          final initPReferenceTime = type == "PredictionService" ? initP.startTime : initP.referenceTime;
          final predictionDiff = trackStartTime!.difference(initPReferenceTime).inSeconds;
          final newPredictionStartTime = localStartTime!.add(Duration(seconds: predictionDiff));
          final initPredictionUpdated = type == "PredictionService"
              ? psPredictionWithNewTime(newPredictionStartTime, initP)
              : pPredictionWithNewTime(newPredictionStartTime, initP);
          final message = createMessageFromPrediction(initPredictionUpdated.toJson());
          log.i("$type : Mocking init prediction at time $newPredictionStartTime");
          _updates.add([MqttReceivedMessage(topic, message)]);
          initPrediction = null;
        }

        log.i("$type : New mock prediction in $timeDiff seconds.");
        final predictionDiff = trackStartTime!.difference(referenceTime).inSeconds;
        final newPredictionStartTime = localStartTime!.add(Duration(seconds: predictionDiff));
        final predictionUpdated = type == "PredictionService"
            ? psPredictionWithNewTime(newPredictionStartTime, p)
            : pPredictionWithNewTime(newPredictionStartTime, p);
        final message = createMessageFromPrediction(predictionUpdated.toJson());
        final timer = Timer(Duration(seconds: timeDiff), () {
          _updates.add([MqttReceivedMessage(topic, message)]);
        });
        if (newPredictionTimersBySgId.containsKey(topic)) {
          newPredictionTimersBySgId[topic]!.add(timer);
        } else {
          newPredictionTimersBySgId[topic] = [timer];
        }
      }
    }

    return null;
  }

  @override
  void disconnect() {
    newPredictionTimersBySgId.forEach((key, value) {
      for (final timer in value) {
        timer.cancel();
      }
    });
    newPredictionTimersBySgId.clear();
    super.connectionStatus?.state = MqttConnectionState.disconnected;
  }
}
