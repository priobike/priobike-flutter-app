import 'dart:convert';

import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/settings/models/auth.dart';
import 'package:priobike/settings/models/backend.dart';

class Auth {
  /// The logger for this service.
  static final log = Logger("Auth");

  /// The current loaded backend.
  static Backend? backend;

  /// The current loaded auth config.
  static AuthConfig? auth;

  /// Load the auth from the backend.
  static Future<AuthConfig> load(Backend currentBackend) async {
    if (backend == currentBackend && auth != null) return Auth.auth!;
    final url = "https://${currentBackend.path}/auth/config.json";
    final response = await Http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));

    AuthConfig loadedAuth;
    if (response.statusCode != 200) {
      final err = "Auth could not be fetched from endpoint $url: ${response.body}";
      log.e(err);

      // FIXME: Remove this fallback, after we fully deployed the auth service.
      switch (currentBackend) {
        case Backend.staging:
          loadedAuth = AuthConfig.stagingBackup;
          log.w("Using backup auth for staging.");
        case Backend.production:
          loadedAuth = AuthConfig.productionBackup;
          log.w("Using backup auth for production.");
        case Backend.release:
          loadedAuth = AuthConfig.releaseBackup;
          log.w("Using backup auth for release.");
      }
    } else {
      final decoded = json.decode(response.body);
      loadedAuth = AuthConfig.fromJson(decoded);
    }

    auth = loadedAuth;
    backend = currentBackend;
    return auth!;
  }
}
