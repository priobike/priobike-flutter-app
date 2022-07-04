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

import 'package:priobike/v2/common/logger.dart';
import 'package:priobike/utils/toast.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:http/http.dart' as http;

import '../services/api.dart';

class RemoteSession {
  late WebSocketChannel socket;
  Peer? jsonRPC;

  StreamController<RouteResponse> routeStreamController =
      StreamController<RouteResponse>();

  StreamController<Recommendation> recommendationStreamController =
      StreamController<Recommendation>();

  http.Client httpClient = http.Client();

  String? sessionId;
  String host;
  String clientId;

  bool weClosedTheWebsocket = false;

  Logger log = Logger("RemoteSession");

  RemoteSession(this.host, this.clientId);

  Future<String?> authenticate() async {
    http.Response response = await httpClient
        .post(Uri.parse(Api.authenticationUrl(host)),
            body: json.encode(
              AuthRequest(clientId: clientId).toJson(),
            ))
        .onError((error, stackTrace) {
      log.e("Fehler bei Auth Request:");
      log.e(error);
      ToastMessage.showError(error.toString());
      throw Exception();
    });

    if (response.statusCode != 200) {
      ToastMessage.showError(response.body);
      throw Exception();
    }

    log.i('<- AuthResponse');
    try {
      sessionId = AuthResponse.fromJson(json.decode(response.body)).sessionId!;
      log.i('Your sessionId is $sessionId');
      return sessionId;
    } catch (error) {
      log.e(error);
      ToastMessage.showError(error.toString());
      throw Error();
    }
  }

  void connectViaWebSocket(String sessionId) async {
    log.i("<-> Establish WebSocket Connection");
    log.i(Api.backendWebSocketUrl(host, sessionId));

    weClosedTheWebsocket = false;

    socket = WebSocketChannel.connect(
      Uri.parse(Api.backendWebSocketUrl(host, sessionId)),
    );

    jsonRPC = Peer(socket.cast<String>());

    jsonRPC?.listen().then((done) {
      log.i('Websocket closed');

      if (weClosedTheWebsocket) return;

      log.w(
          'Disconnected: ${socket.closeCode} ${socket.closeReason}, reconnect in 2 seconds');
      Future.delayed(
        const Duration(seconds: 2),
        () => connectViaWebSocket(sessionId),
      );
    });

    jsonRPC?.registerMethod('RecommendationUpdate', (Parameters params) {
      log.i('<- Recommendation');
      // log.i(params.value.toString());
      try {
        Recommendation recommendation = Recommendation.fromJsonRPC(params);
        if (recommendation.error) log.e(recommendation.errorMessage);
        recommendationStreamController.add(recommendation);
      } catch (error) {
        log.e(error);
        ToastMessage.showError(error.toString());
      }
    });
  }

  void updateRoute(List<Point> waypoints) {
    log.i('-> RouteRequest');
    log.i(Api.getRouteUrl(host));

    try {
      httpClient
          .post(
              Uri.parse(
                Api.getRouteUrl(host),
              ),
              body: json.encode(RouteRequest(
                sessionId: sessionId,
                waypoints: waypoints,
              ).toJson()))
          .then((http.Response response) async {
        if (response.statusCode != 200) {
          log.e(response.body);

          if (response.statusCode == 403 || response.statusCode == 401) {
            ToastMessage.showError(
              "Session ist abgelaufen. Versuche erneut...",
            );

            var sessionId = await authenticate();
            connectViaWebSocket(sessionId!);
            return;
          }

          ToastMessage.showError("${response.statusCode} ${response.body}");
          return;
        }
        log.i('<- RouteResponse');
        log.i(json.decode(response.body));
        routeStreamController.add(
          RouteResponse.fromJson(json.decode(response.body)),
        );
      });
    } catch (error) {
      log.e(error);
      ToastMessage.showError(error.toString());
    }
  }

  void updatePosition(
    double lat,
    double lon,
    double speed,
    double accuracy,
    double heading,
    DateTime? timestamp,
  ) {
    log.i('-> Position');
    try {
      log.i(UserPosition(
        lat: lat,
        lon: lon,
        speed: speed,
        accuracy: accuracy,
        heading: heading,
        timestamp: timestamp,
      ).toJson());

      jsonRPC?.sendNotification(
        'PositionUpdate',
        UserPosition(
          lat: lat,
          lon: lon,
          speed: speed,
          accuracy: accuracy,
          heading: heading,
          timestamp: timestamp,
        ).toJson(),
      );
    } catch (error) {
      log.e(error.toString());
      ToastMessage.showError(error.toString());
    }
  }

  void startRecommendation() {
    log.i('-> Start Navigation');
    try {
      jsonRPC?.sendRequest(
        'Navigation',
        NavigationRequest(active: true).toJson(),
      );
    } catch (error) {
      log.e(error.toString());
      ToastMessage.showError(error.toString());
    }
  }

  void stopRecommendation() {
    log.i('-> Stop Navigation');
    try {
      jsonRPC?.sendRequest(
        'Navigation',
        NavigationRequest(active: false).toJson(),
      );
    } catch (error) {
      log.e(error.toString());
      ToastMessage.showError(error.toString());
    }
  }

  void closeSession() async {
    weClosedTheWebsocket = true;
    await jsonRPC?.close();
  }
}
