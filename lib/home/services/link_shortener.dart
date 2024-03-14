import 'dart:convert';

import 'package:priobike/http.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

class LinkShortener {
  /// Shorten long link.
  static Future<String?> createShortLink(String longLink) async {
    final backend = getIt<Settings>().backend;
    String backendPath = backend.path;
    final linkShortenerUrl = 'https://$backendPath/link/rest/v3/short-urls';
    final linkShortenerEndpoint = Uri.parse(linkShortenerUrl);
    DateTime now = DateTime.now();
    String validUntil = DateTime(now.year, now.month + 1, now.day).toIso8601String();
    validUntil = validUntil.split('.')[0];
    validUntil += '+00:00';
    final longUrlJson = json.encode({
      "longUrl": longLink,
      "validUntil": validUntil,
      "findIfExists": true,
      "validateUrl": false,
      "forwardQuery": true
    });
    final apiKey = backend.linkShortenerApiKey;
    final shortLinkResponse = await Http.post(linkShortenerEndpoint, headers: {'X-Api-Key': apiKey}, body: longUrlJson);
    try {
      return json.decode(shortLinkResponse.body)['shortUrl'];
    } catch (e) {
      log.e('Failed to get short link.');
      return null;
    }
  }

  /// Resolve short link.
  static Future<String?> resolveShortLink(String shortLink) async {
    // Shortcuts from production and release should be working with each others backend.
    // Therefore, try fetch from the current backend and (if failed) from the other backend.
    // Only staging is not compatible with the other backends.
    final backend = getIt<Settings>().backend;
    final String? result = await _fetch(backend, shortLink);
    if (result != null) return result;
    if (backend == Backend.staging) return null;

    // Try to fetch from the other backend.
    final otherBackend = backend == Backend.production ? Backend.release : Backend.production;
    return await _fetch(otherBackend, shortLink);
  }

  /// Fetch long link from backend.
  static Future<String?> _fetch(Backend backend, String shortLink) async {
    try {
      List<String> subUrls = shortLink.split('/');
      String backendPath = backend.path;
      final parseShortLinkEndpoint = Uri.parse('https://$backendPath/link/rest/v3/short-urls/${subUrls.last}');
      final apiKey = backend.linkShortenerApiKey;
      final longLinkResponse = await Http.get(parseShortLinkEndpoint, headers: {'X-Api-Key': apiKey});
      final String longUrl = json.decode(longLinkResponse.body)['longUrl'];
      return longUrl;
    } catch (e) {
      return null;
    }
  }
}
