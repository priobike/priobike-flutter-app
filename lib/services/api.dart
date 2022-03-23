class Api {
  static const hostProduction = 'priobike.vkw.tu-dresden.de/production';
  static const hostStaging = 'priobike.vkw.tu-dresden.de/staging';

  static String backendRestUrl(host) => 'https://$host/session-wrapper';
  static String backendWebSocketUrl(host, sessionId) =>
      'wss://$host/session-wrapper/websocket/sessions/$sessionId';

  static String authenticationUrl(host) =>
      '${backendRestUrl(host)}/authentication';
  static String getRouteUrl(host) => '${backendRestUrl(host)}/getroute';
}
