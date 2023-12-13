import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:priobike/logging/logger.dart';

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
  static void setCookies(http.BaseResponse response) {
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
  static Future<http.Response> get(Uri url, {dynamic headers}) async {
    // Add the cookies to the request.
    final cookieString = Http.cookies.entries.map((e) => "${e.key}=${e.value}").join("; ");
    headers ??= {"Cookie": cookieString};
    // Passing the sticky cookie will allow us to connect to the same backend.
    http.Response response = await _client.get(url, headers: headers);
    setCookies(response);
    return response;
  }

  /// Make a POST request.
  static Future<http.Response> post(Uri url, {dynamic body, dynamic headers}) async {
    final cookieString = Http.cookies.entries.map((e) => "${e.key}=${e.value}").join("; ");
    headers ??= {"Cookie": cookieString};
    // Passing the sticky cookie will allow us to connect to the same backend.
    http.Response response = await _client.post(url, body: body, headers: headers);
    setCookies(response);
    return response;
  }

  /// Make a multipart POST request.
  static Future<http.Response> multipartPost(
    Uri url, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final cookieString = Http.cookies.entries.map((e) => "${e.key}=${e.value}").join("; ");
    final headers = {"Cookie": cookieString};
    // Passing the sticky cookie will allow us to connect to the same backend.
    final request = http.MultipartRequest("POST", url);
    request.headers.addAll(headers);
    if (fields != null) request.fields.addAll(fields);
    if (files != null) request.files.addAll(files);
    http.StreamedResponse response = await request.send();
    setCookies(response);
    return http.Response.fromStream(response);
  }
}
