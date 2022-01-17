import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
        .post(Uri.parse(Api.authenticationUrl(Api.authenticationUrl(host))),
            body: json.encode(AuthRequest(clientId: clientId).toJson()))
        .then((http.Response response) {
      log.i('<- AuthResponse');
      try {
        sessionId =
            AuthResponse.fromJson(json.decode(response.body)).sessionId!;
      } catch (error) {
        log.e(error);
        Fluttertoast.showToast(
          msg: "Fehler: $error",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
      log.i('Your sessionId is $sessionId');
      connectViaWebSocket();
      onDone();
    }).onError((error, stackTrace) {
      log.e("Fehler bei Auth Request:");
      log.e(error);
      Fluttertoast.showToast(
        msg: "Fehler: $error",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
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
          'Disconnected: ${socket.closeCode} ${socket.closeReason}, reconnect in 3 seconds');
      Future.delayed(
        const Duration(seconds: 3),
        () => connectViaWebSocket(),
      );
    });

    jsonRPC.registerMethod('RecommendationUpdate', (Parameters params) {
      log.i('<- Recommendation');
      try {
        Recommendation recommendation = Recommendation.fromJsonRPC(params);
        if (recommendation.error) log.e(recommendation.errorMessage);
        recommendationStreamController.add(recommendation);
      } catch (error) {
        log.e(error);
        Fluttertoast.showToast(
          msg: "Fehler: $error",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    });
  }

  void updateRoute(List<Point> waypoints) {
    log.i('-> RouteRequest');
    log.i(Api.getRouteUrl(host));

    httpClient
        .post(
            Uri.parse(
              Api.getRouteUrl(Api.getRouteUrl(host)),
            ),
            body: json.encode(RouteRequest(
              sessionId: sessionId,
              waypoints: waypoints,
            ).toJson()))
        .then((http.Response response) {
      log.i('<- RouteResponse');
      try {
        routeStreamController
            .add(RouteResponse.fromJson(json.decode(response.body)));
      } catch (error) {
        log.e(error);
        Fluttertoast.showToast(
          msg: "Fehler: $error",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    });
  }

  void updatePosition(
    double lat,
    double lon,
    double speed,
  ) {
    log.i('-> Position');
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
    log.i('-> Start Navigation');
    jsonRPC.sendRequest(
      'Navigation',
      NavigationRequest(active: true).toJson(),
    );
  }

  void stopRecommendation() {
    log.i('-> Stop Navigation');
    jsonRPC.sendRequest(
      'Navigation',
      NavigationRequest(active: false).toJson(),
    );
  }
}
