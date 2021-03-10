import 'dart:convert';

import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import 'package:priobike/models/recommendation.dart';
import 'package:priobike/models/user_position.dart';
import 'package:priobike/session/session.dart';

class RemoteSession extends Session {
  String _sessionId;
  StompClient _stompClient;

  RemoteSession({String id}) {
    this._sessionId = id;

    onConnect(StompClient client, StompFrame frame) {
      print('connected to STOMP Server');

      client.subscribe(
        destination: '/queue/${this._sessionId}/recommendation',
        callback: (StompFrame frame) {
          super
              .recommendationStreamController
              .add(Recommendation.fromJson(json.decode(frame.body)));
        },
      );
    }

    onDisconnect(StompFrame frame) {
      print("disconnected from STOMP Server");
    }

    print("trying to connect");
    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://10.0.2.2:8080/stomp', // local address for development
        stompConnectHeaders: {'clientId': 'my_device_sessionId_or_something'},
        onConnect: onConnect,
        onDisconnect: onDisconnect,
        onStompError: (StompFrame frame) => print("error: " + frame.body),
        onWebSocketError: (dynamic error) => print(error.toString()),
        connectionTimeout: Duration(seconds: 30),
      ),
    );

    _stompClient.activate();
  }

  @override
  updatePosition(
    double lat,
    double lon,
    int speed,
  ) {
    _stompClient.send(
      destination: '/queue/${this._sessionId}/position',
      body: json.encode(
        new UserPosition(
          lat: lat,
          lon: lon,
          speed: speed,
        ).toJson(),
      ),
    );
  }

  @override
  dispose() {
    super.dispose();
    _stompClient.deactivate();
  }
}
