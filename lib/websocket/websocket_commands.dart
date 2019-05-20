import 'web_socket_method.dart';
import 'package:bike_now/configuration.dart';

abstract class WebSocketCommand{
  WebSocketMethod method;
  bool requiresAuthentication;
  String sessionId;
}

class Login implements WebSocketCommand {
  int version = 1;
  String apiKey = Configuration.apiKey;
  @override
  WebSocketMethod method = WebSocketMethod.login;

  @override
  bool requiresAuthentication = false;

  @override
  String sessionId;

  Login(this.sessionId);

  Map<String, dynamic> toJson() =>
      {
        'method': WebSocketMethodHelper.getValue(method),
        'sessionId': '"$sessionId"',
        'apiKey' : '"$apiKey"',
        'version' : version
      };

}

class Logout implements WebSocketCommand {
  @override
  WebSocketMethod method = WebSocketMethod.logout;

  @override
  bool requiresAuthentication = true;

  @override
  String sessionId;

  Logout(this.sessionId);

  Map<String, dynamic> toJson() =>
      {
        'method': WebSocketMethodHelper.getValue(method),
        'sessionId': '"$sessionId"',
      };
}

class CalcRoute implements WebSocketCommand {
  double sourceLat;
  double sourceLong;
  double targetLat;
  double targetLong;

  @override
  WebSocketMethod method = WebSocketMethod.calcRoute;

  @override
  bool requiresAuthentication = true;

  @override
  String sessionId;

  CalcRoute(this.sourceLat,this.sourceLong,this.targetLat,this.targetLong,this.sessionId);

  Map<String, dynamic> toJson() =>
      {
        'method': WebSocketMethodHelper.getValue(method),
        'sessionId': '"$sessionId"',
        'lat1': sourceLat,
        'lon1': sourceLong,
        'lat2': targetLat,
        'lon2': targetLong
      };
}

class PushLocations implements WebSocketCommand {
  @override
  WebSocketMethod method = WebSocketMethod.pushLocations;

  @override
  bool requiresAuthentication = true;

  @override
  String sessionId;

}

class Ping implements WebSocketCommand {
  @override
  WebSocketMethod method = WebSocketMethod.ping;

  @override
  bool requiresAuthentication = true;

  @override
  String sessionId;

  Ping(this.sessionId);

  Map<String, dynamic> toJson() =>
      {
        'method': WebSocketMethodHelper.getValue(method),
        'sessionId': '"$sessionId"'
      };

}

