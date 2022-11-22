import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/ride/messages/auth.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class Session with ChangeNotifier {
  final log = Logger("Session");

  /// The client id of this session.
  var clientId = "beta-app-" + UniqueKey().toString();

  /// The active session id, if authenticated.
  /// Is set by: [openSession].
  /// Is unset by: [closeSession].
  String? sessionId;

  Session();

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
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;
    final authEndpoint = Uri.parse('https://$baseUrl/session-wrapper/authentication');
    final response = await Http.post(authEndpoint, body: json.encode(authRequest.toJson())).onError(
      (error, stackTrace) {
        log.e("Error during authentication: $error");
        ToastMessage.showError(error.toString());
        throw Exception();
      },
    );

    if (response.statusCode != 200) {
      final err = "Error during authentication with endpoint $authEndpoint: ${response.body}";
      log.e(err);
      ToastMessage.showError(err);
      throw Exception(err);
    }

    try {
      final authResponse = AuthResponse.fromJson(json.decode(response.body));
      log.i("Successfully authenticated with endpoint $authEndpoint: ${response.body}");
      sessionId = authResponse.sessionId!;
      return sessionId!;
    } catch (error, stack) {
      final hint = "Error during authentication: $error";
      if (!kDebugMode) {
        await Sentry.captureException(error, stackTrace: stack, hint: hint);
      }
      log.e(hint);
      ToastMessage.showError(hint);
      throw Exception(hint);
    }
  }

  /// Close the session.
  Future<void> closeSession() async {
    sessionId = null;
  }
}
