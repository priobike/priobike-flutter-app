import 'dart:convert';
import 'dart:typed_data';

import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/http.dart';

class LinkShortener {
  /// Create sharing link of shortcut.
  String getLongLink(Shortcut shortcut) {
    final Map<String, dynamic> shortcutJson = shortcut.toJson();
    final str = json.encode(shortcutJson);
    final bytes = utf8.encode(str);
    final base64Str = base64.encode(bytes);
    const scheme = 'https';
    const host = 'priobike.vkw.tu-dresden.de';
    const route = 'import';
    return '$scheme://$host/$route/$base64Str';
  }

  Future<String> getShortLink(String longLink) async {
    // TODO staging vs production
    const linkShortenerUrl = 'https://priobike.vkw.tu-dresden.de/staging/link/rest/v3/short-urls';
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
    final shortLinkResponse = await Http.post(linkShortenerEndpoint,
        headers: {'X-Api-Key': '8a1e47f1-36ac-44e8-b648-aae112f97208'}, body: longUrlJson);
    return json.decode(shortLinkResponse.body)['shortUrl'];
  }

  Future<Uint8List> getQr(String longLink) async {
    final String shortLink = await getShortLink(longLink);
    final String shortCode = shortLink.split('/').last;
    final String qrUrl =
        'https://priobike.vkw.tu-dresden.de/staging/link/$shortCode/qr-code?size=300&format=png&errorCorrection=L';
    final qrEndpoint = Uri.parse(qrUrl);
    final qrResponse = await Http.get(qrEndpoint);
    return qrResponse.bodyBytes;
  }
}
