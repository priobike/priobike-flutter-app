import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/ride/messages/auth.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class SessionService with ChangeNotifier {
  Logger log = Logger("SessionService");

  /// The HTTP client used to make requests to the backend.
  http.Client httpClient = http.Client();

  /// The client id of this session.
  var clientId = "beta-app-" + UniqueKey().toString();

  /// The active session id, if authenticated.
  /// Is set by: [openSession].
  /// Is unset by: [closeSession].
  String? sessionId;

  SessionService();

  /// Reset the session service.
  Future<void> reset() async {
    await closeSession();
  }

  /// Check if the session is active.
  bool isActive() => sessionId != null;

  /// Open the session by authentication with the backend.
  Future<String> openSession(BuildContext context) async {
    // If the session is already open, do nothing.
    if (sessionId != null) return sessionId!;

    final authRequest = AuthRequest(clientId: clientId);
    final settings = Provider.of<SettingsService>(context, listen: false);
    final baseUrl = settings.backend.path;
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
    sessionId = null;
  }
}