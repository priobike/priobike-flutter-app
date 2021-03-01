import 'dart:convert';

import 'package:http/http.dart' as HTTP;

import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import 'package:priobike/config/config.dart';
import 'package:priobike/models/api/api_route.dart';
import 'package:priobike/models/recommendation.dart';
import 'package:priobike/models/route_request.dart';
import 'package:priobike/models/user_position.dart';
import 'package:priobike/session/session.dart';

class RemoteSession extends Session {
  String _id;

  HTTP.Client _httpClient = HTTP.Client();
  StompClient _stompClient;

  String positionDestination(String sessionId) => '/queue/$sessionId/position';
  String recommendationDestination(String sessionId) =>
      '/queue/$sessionId/recommendation';

  RemoteSession({String id}) {
    this._id = id;

    onConnect(StompClient client, StompFrame frame) {
      print('connected to STOMP Server');

      client.subscribe(
        destination: recommendationDestination(_id),
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
        url: 'ws://10.0.2.2:8080',
        onConnect: onConnect,
        onDisconnect: onDisconnect,
        onStompError: (StompFrame frame) => print("error: " + frame.body),
        onWebSocketError: (dynamic error) => print(error.toString()),
        connectionTimeout: Duration(seconds: 10),
        reconnectDelay: 1500,
        heartbeatOutgoing: 2000,
        heartbeatIncoming: 2000,
      ),
    );
  }

  @override
  updateRoute(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) {
    _httpClient
        .post('${Config.GATEWAY_URL}:${Config.GATEWAY_PORT}/routing/getroute',
            body: new RouteRequest(
              fromLat: fromLat,
              fromLon: fromLon,
              toLat: toLat,
              toLon: toLon,
            ).toJson())
        .then((HTTP.Response response) {
      super
          .routeStreamController
          .add(ApiRoute.fromJson(json.decode(response.body)));
    });
  }

  @override
  updatePosition(
    double lat,
    double lon,
    int speed,
  ) {
    _stompClient.send(
      destination: positionDestination(this._id),
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
  void startRecommendation() {
    _httpClient
        .get('${Config.GATEWAY_URL}:${Config.GATEWAY_PORT}/routing/start')
        .then((HTTP.Response response) {
      print(response.body);
    });
  }

  @override
  stopRecommendation() {
    _httpClient
        .get('${Config.GATEWAY_URL}:${Config.GATEWAY_PORT}/routing/stop')
        .then((HTTP.Response response) {
      print(response.body);
    });
  }

  @override
  dispose() {
    super.dispose();
    _httpClient.close();
    _stompClient.deactivate();
  }
}
