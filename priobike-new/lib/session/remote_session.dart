import 'dart:async';
import 'dart:convert';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:priobike/models/auth_request.dart';
import 'package:priobike/models/auth_response.dart';
import 'package:priobike/models/navigation_request.dart';
import 'package:priobike/models/point.dart';
import 'package:priobike/models/recommendation.dart';
import 'package:priobike/models/route_request.dart';
import 'package:priobike/models/route_response.dart';
import 'package:priobike/models/user_position.dart';

import 'package:priobike/utils/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:http/http.dart' as http;

import 'config.dart';

class RemoteSession {
  late WebSocketChannel socket;
  late Peer jsonRPC;

  StreamController<RouteResponse> routeStreamController =
      StreamController<RouteResponse>();

  StreamController<Recommendation> recommendationStreamController =
      StreamController<Recommendation>();

  http.Client httpClient = http.Client();

  String? sessionId;

  Logger log = Logger("RemoteSession");

  void connect(String sessionId) {
    socket = WebSocketChannel.connect(
        Uri.parse(Config.sessionwrapperWebSocketURI + sessionId));

    jsonRPC = Peer(socket.cast<String>());

    jsonRPC.listen().then((done) {
      log.w(
          'Disconnected: ${socket.closeCode} ${socket.closeReason}, reconnect in 3 seconds');
      Future.delayed(const Duration(seconds: 3), () => connect(sessionId));
    });

    jsonRPC.registerMethod('RecommendationUpdate', (Parameters params) {
      Recommendation recommendation = Recommendation.fromJsonRPC(params);

      if (recommendation.error) {
        log.e(recommendation.errorMessage);
      }

      recommendationStreamController.add(recommendation);
    });
  }

  RemoteSession({required String clientId, required Function onDone}) {
    httpClient
        .post(Uri.parse('${Config.sessionwrapperRestUri}authentication'),
            body: json.encode(AuthRequest(clientId: clientId).toJson()))
        .then((http.Response response) {
      sessionId = AuthResponse.fromJson(json.decode(response.body)).sessionId!;
      log.i('Your sessionId is $sessionId');
      connect(sessionId!);
      onDone();
    }).onError((error, stackTrace) {
      log.e("Fehler bei Auth Request:");
      log.e(error);
    }); // TODO: proper Error Handling, show a toast or something
  }

  void updateRoute(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) {
    httpClient
        .post(Uri.parse('${Config.sessionwrapperRestUri}getroute'),
            body: json.encode(RouteRequest(
              sessionId: sessionId,
              from: Point(lat: fromLat, lon: fromLon),
              to: Point(lat: toLat, lon: toLon),
            ).toJson()))
        .then((http.Response response) {
      routeStreamController
          .add(RouteResponse.fromJson(json.decode(response.body)));
    });
  }

  void updatePosition(
    double lat,
    double lon,
    double speed,
  ) {
    jsonRPC.sendNotification(
      'PositionUpdate',
      UserPosition(
        lat: lat,
        lon: lon,
        speed: speed,
      ).toJson(),
    );
  }

  void startRecommendation() {
    jsonRPC.sendRequest(
      'Navigation',
      NavigationRequest(active: true).toJson(),
    );
  }

  void stopRecommendation() {
    jsonRPC.sendRequest(
      'Navigation',
      NavigationRequest(active: false).toJson(),
    );
  }
}
