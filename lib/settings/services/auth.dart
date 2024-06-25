import 'dart:convert';

import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/settings/models/auth.dart';
import 'package:priobike/settings/models/backend.dart';

class Auth {
  /// The logger for this service.
  static final log = Logger("Auth");

  /// The current loaded auth configs.
  static Map<String, AuthConfig> authConfigs = {};

  /// Load the auth from the backend.
  static Future<AuthConfig> load(Backend currentBackend) async {
    if (authConfigs.containsKey(currentBackend.name)) return Auth.authConfigs[currentBackend.name]!;
    final url = "https://${currentBackend.path}/auth/config.json";
    // Note: it's intended that these credentials are public.
    final headers = {'authorization': 'Basic ${base64Encode(utf8.encode('auth:fMG3dtQtYRyMdE34'))}'};
    final response = await Http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 4));

    AuthConfig loadedAuth;
    if (response.statusCode != 200) {
      throw Exception("Failed to load auth config: ${response.statusCode}");
    } else {
      final decoded = json.decode(response.body);
      loadedAuth = AuthConfig.fromJson(decoded);
    }

    authConfigs[currentBackend.name] = loadedAuth;
    return loadedAuth;
  }
}
