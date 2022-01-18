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
import 'package:priobike/utils/toast.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:http/http.dart' as http;

import '../services/api.dart';

class RemoteSession {
  late WebSocketChannel socket;
  late Peer jsonRPC;

  StreamController<RouteResponse> routeStreamController =
      StreamController<RouteResponse>();

  StreamController<Recommendation> recommendationStreamController =
      StreamController<Recommendation>();

  http.Client httpClient = http.Client();

  String host;

  String? sessionId;

  Logger log = Logger("RemoteSession");

  RemoteSession({
    required this.host,
    required String clientId,
    required Function onDone,
  }) {
    log.i('-> AuthRequest');
    log.i(Api.authenticationUrl(host));

    httpClient
        .post(Uri.parse(Api.authenticationUrl(host)),
            body: json.encode(AuthRequest(clientId: clientId).toJson()))
        .then((http.Response response) {
      if (response.statusCode != 200) {
        ToastMessage.showError(response.body);
        return;
      }

      log.i('<- AuthResponse');
      try {
        sessionId =
            AuthResponse.fromJson(json.decode(response.body)).sessionId!;
      } catch (error) {
        log.e(error);
        ToastMessage.showError(error.toString());
      }
      log.i('Your sessionId is $sessionId');
      connectViaWebSocket();
      onDone();
    }).onError((error, stackTrace) {
      log.e("Fehler bei Auth Request:");
      log.e(error);
      ToastMessage.showError(error.toString());
    });
  }

  void connectViaWebSocket() {
    log.i("<-> Establish WebSocket Connection");
    log.i(Api.backendWebSocketUrl(host, sessionId));

    socket = WebSocketChannel.connect(
        Uri.parse(Api.backendWebSocketUrl(host, sessionId)));

    jsonRPC = Peer(socket.cast<String>());

    jsonRPC.listen().then((done) {
      log.w(
          'Disconnected: ${socket.closeCode} ${socket.closeReason}, reconnect in 2 seconds');
      Future.delayed(
        const Duration(seconds: 2),
        () => connectViaWebSocket(),
      );
    });

    jsonRPC.registerMethod('RecommendationUpdate', (Parameters params) {
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
          .then((http.Response response) {
        if (response.statusCode != 200) {
          log.e(response.body);

          if (response.statusCode == 403 || response.statusCode == 401) {
            ToastMessage.showError(
              "Session ist abgelaufen. Starten Sie die App neu.",
            );
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
  ) {
    log.i('-> Position');
    try {
      jsonRPC.sendNotification(
        'PositionUpdate',
        UserPosition(
          lat: lat,
          lon: lon,
          speed: speed,
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
      jsonRPC.sendRequest(
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
      jsonRPC.sendRequest(
        'Navigation',
        NavigationRequest(active: false).toJson(),
      );
    } catch (error) {
      log.e(error.toString());
      ToastMessage.showError(error.toString());
    }
  }

  void clearSessionId() {
    sessionId = null;
  }
}
