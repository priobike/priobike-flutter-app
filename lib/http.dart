import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:priobike/logging/logger.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// For older Android devices (Android 5), there will sometimes be a
/// HTTP error due to an expired certificate. This certificate lies within
/// the Android operating system and is not part of the app. For our app
/// to work on older Android devices, we need to ignore the certificate error.
/// Note that this is a workaround and should be handled with care.
/// See: https://github.com/flutter/flutter/issues/19588#issuecomment-406779390
class OldAndroidHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class Http {
  static final log = Logger("Http");

  /// The client used by the app.
  static late http.Client _client;

  /// Init the http client.
  static void initClient() {
    HttpOverrides.global = OldAndroidHttpOverrides();
    _client = http.Client();
  }

  /// The cookies sent by the backend.
  /// This is necessary for load balancing (stickyness).
  static Map<String, String> cookies = {};

  /// Set the cookies.
  static void setCookies(http.Response response) {
    if (response.headers.containsKey("set-cookie")) {
      // Extract the cookies from the response.
      final header = response.headers["set-cookie"]!;
      final cookies = header.split(";");
      for (var cookie in cookies) {
        final parts = cookie.split("=");
        Http.cookies[parts[0]] = parts[1];
      }
      log.i("Updated session cookies: ${Http.cookies}");
    }
  }

  /// Make a GET request.
  static Future<http.Response> get(Uri url) async {
    // Add the cookies to the request.
    final cookieString = Http.cookies.entries.map((e) => "${e.key}=${e.value}").join("; ");
    final headers = {"Cookie": cookieString};
    // Passing the sticky cookie will allow us to connect to the same backend.
    http.Response response = await _client.get(url, headers: headers);
    setCookies(response);
    return response;
  }

  /// Make a POST request.
  static Future<http.Response> post(Uri url, {dynamic body}) async {
    final cookieString = Http.cookies.entries.map((e) => "${e.key}=${e.value}").join("; ");
    final headers = {"Cookie": cookieString};
    // Passing the sticky cookie will allow us to connect to the same backend.
    http.Response response = await _client.post(url, body: body, headers: headers);
    setCookies(response);
    return response;
  }

  /// Connect a WebSocket.
  static WebSocketChannel connectWebSocket(Uri url) {
    final cookieString = Http.cookies.entries.map((e) => "${e.key}=${e.value}").join("; ");
    final headers = {"Cookie": cookieString};
    // Passing the sticky cookie will allow us to connect to the same backend.
    return IOWebSocketChannel.connect(url, headers: headers);
  }
}
