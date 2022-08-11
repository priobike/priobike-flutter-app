
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:priobike/v2/common/logger.dart';
import 'package:priobike/v2/session/models/auth.dart';
import 'package:priobike/v2/session/views/toast.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SessionService with ChangeNotifier {
  Logger log = Logger("SessionService");

  /// The web socket channel to the backend.
  WebSocketChannel? socket;

  /// The peer used to communicate JSON RPC messages to the backend.
  Peer? jsonRPCPeer;

  /// The HTTP client used to make requests to the backend.
  http.Client httpClient = http.Client();

  /// The client id of this session.
  final clientId = "beta-app-" + const Uuid().v4();

  /// The active session id, if authenticated.
  /// Is set by: [openSession].
  /// Is unset by: [closeSession].
  String? sessionId;

  /// The backend host of the session.
  String baseUrl;

  /// The REST url to the session service.
  String get restUrl => 'https://$baseUrl/session-wrapper';

  /// The authentication url.
  String get authUrl => '$restUrl/authentication';

  /// The route url.
  String get routeUrl => '$restUrl/getroute';

  /// The WS url to the session service.
  /// Is `null` if the session is not authenticated.
  String? get wsUrl => sessionId != null ? 'wss://$baseUrl/session-wrapper/websocket/sessions/$sessionId!' : null;

  SessionService({required this.baseUrl});

  /// Open the session by authentication with the backend.
  Future<String> openSession() async {
    // If the session is already open, do nothing.
    if (sessionId != null) return sessionId!;

    final authRequest = AuthRequest(clientId: clientId);
    final authEndpoint = Uri.parse('https://$baseUrl/session-wrapper/authentication');
    http.Response response = await httpClient
      .post(authEndpoint, body: json.encode(authRequest.toJson()))
      .onError((error, stackTrace) {
        log.e("Error during authentication: $error");
        ToastMessage.showError(error.toString());
        throw Exception();
      });

    if (response.statusCode != 200) {
      final err = "Error during authentication with endpoint $authEndpoint: ${response.body}";
      log.e(err); ToastMessage.showError(err); throw Exception(err);
    }

    log.i('<- AuthResponse');
    try {
      final authResponse = AuthResponse.fromJson(json.decode(response.body));
      log.i("Successfully authenticated with endpoint $authEndpoint: ${response.body}");
      sessionId = authResponse.sessionId!;
      return sessionId!;
    } catch (error) {
      final err = "Error during authentication: $error";
      log.e(err); ToastMessage.showError(err); throw Exception(err);
    }
  }

  /// Close the session.
  Future<void> closeSession() async {
    await jsonRPCPeer?.close();
    sessionId = null;
  }
}

class StagingSessionService extends SessionService {
  StagingSessionService() : super(baseUrl: 'priobike.vkw.tu-dresden.de/staging');
}

class ProductionSessionService extends SessionService {
  ProductionSessionService() : super(baseUrl: 'priobike.vkw.tu-dresden.de/production');
}