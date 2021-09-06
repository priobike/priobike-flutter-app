import 'dart:convert';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:priobike/config/config.dart';
import 'package:priobike/config/logger.dart';
import 'package:priobike/models/auth_request.dart';
import 'package:priobike/models/auth_response.dart';
import 'package:priobike/models/recommendation.dart';
import 'package:priobike/models/user_position.dart';
import 'package:priobike/session/session.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:http/http.dart' as HTTP;

class RemoteSession extends Session {
  WebSocketChannel socket;
  Peer jsonRPC;

  void connect(String sessionId) {
    socket = WebSocketChannel.connect(
        Uri.parse(Config.SESSIONWRAPPER_WEBSOCKET_URI + sessionId));

    jsonRPC = Peer(socket.cast<String>());

    jsonRPC.listen().then((done) {
      print('Disconnected: ${socket.closeCode} ${socket.closeReason}');
      print('reconnect in 3 seconds');
      Future.delayed(Duration(seconds: 3), () => connect(sessionId));
    });

    jsonRPC.registerMethod('RecommendationUpdate', (Parameters params) {
      print('got recommendation');
      super
          .recommendationStreamController
          .add(Recommendation.fromJsonRPC(params));
    });
  }

  RemoteSession({String clientId}) {
    httpClient
        .post(
            '${Config.SESSIONWRAPPER_HOST}:${Config.SESSIONWRAPPER_PORT}/authentication',
            body: json.encode(new AuthRequest(clientId: clientId).toJson()))
        .then((HTTP.Response response) {
      sessionId = AuthResponse.fromJson(json.decode(response.body)).sessionId;
      log.i('Your sessionId is $sessionId');
      connect(sessionId);
    }).onError(
      (error, stackTrace) => log.e(error),
    ); // TODO: proper Error Handling, show a toast or something
  }

  @override
  void updatePosition(
    double lat,
    double lon,
    int speed,
  ) {
    jsonRPC.sendNotification(
      'PositionUpdate',
      new UserPosition(
        lat: lat,
        lon: lon,
        speed: speed,
      ).toJson(),
    );
  }

  @override
  void startRecommendation() {
    jsonRPC.sendRequest(
      'Navigation',
      {'active': true},
    ).then((value) => print(value));
  }

  @override
  void stopRecommendation() {
    jsonRPC.sendRequest(
      'Navigation',
      {'active': false},
    ).then((value) => print(value));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
