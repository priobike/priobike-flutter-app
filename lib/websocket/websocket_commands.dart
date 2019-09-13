import 'web_socket_method.dart';
import 'package:bike_now_flutter/configuration.dart';
import 'package:bike_now_flutter/models/location.dart';
import 'package:bike_now_flutter/models/subscription.dart';

abstract class WebSocketCommand {
  WebSocketMethod method;
  bool requiresAuthentication;
  String sessionId;
  Map<String, dynamic> toJson();
}

class Logout implements WebSocketCommand {
  @override
  WebSocketMethod method = WebSocketMethod.logout;

  @override
  bool requiresAuthentication = true;

  @override
  String sessionId;

  Logout(this.sessionId);

  Map<String, dynamic> toJson() => {
        'method': WebSocketMethodHelper.getValue(method),
        'sessionId': '$sessionId',
      };
}

class Ping implements WebSocketCommand {
  @override
  WebSocketMethod method = WebSocketMethod.ping;

  @override
  bool requiresAuthentication = true;

  @override
  String sessionId;

  Ping(this.sessionId);

  Map<String, dynamic> toJson() => {
        'method': WebSocketMethodHelper.getValue(method),
        'sessionId': '$sessionId'
      };
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

  Map<String, dynamic> toJson() => {
        'method': WebSocketMethodHelper.getValue(method),
        'sessionId': '$sessionId',
        'apiKey': '$apiKey',
        'version': version
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

  CalcRoute(this.sourceLat, this.sourceLong, this.targetLat, this.targetLong,
      this.sessionId);

  Map<String, dynamic> toJson() => {
        'method': WebSocketMethodHelper.getValue(method),
        'sessionId': '$sessionId',
        'lat1': sourceLat,
        'lon1': sourceLong,
        'lat2': targetLat,
        'lon2': targetLong
      };
}

class PushLocations implements WebSocketCommand {
  List<Location> locations;

  @override
  WebSocketMethod method = WebSocketMethod.pushLocations;

  @override
  bool requiresAuthentication = true;

  @override
  String sessionId;

  PushLocations(this.locations, this.sessionId);

  Map<String, dynamic> toJson() => {
        'method': WebSocketMethodHelper.getValue(method),
        'sessionId': '$sessionId',
        'locationArray': locations.map((i) => (i.toJson())).toList()
      };
}

class UpdateSubscription implements WebSocketCommand {
  List<Subscription> subscriptions;
  @override
  WebSocketMethod method = WebSocketMethod.updateSubscriptions;

  @override
  bool requiresAuthentication = true;

  @override
  String sessionId;

  UpdateSubscription(this.subscriptions, this.sessionId);

  Map<String, dynamic> toJson() => {
        'method': WebSocketMethodHelper.getValue(method),
        'sessionId': '$sessionId',
        'subscriptions': subscriptions.map((sub) => (sub.toJson())).toList()
      };
}

class GetLocationFromAddress implements WebSocketCommand {
  @override
  WebSocketMethod method = WebSocketMethod.getLocationFromAddress;

  @override
  bool requiresAuthentication = true;

  @override
  String sessionId;

  String address;

  GetLocationFromAddress(this.sessionId, this.address);

  Map<String, dynamic> toJson() => {
        'method': WebSocketMethodHelper.getValue(method),
        'sessionId': '$sessionId',
        'address': '$address'
      };
}

class GetAddressFromLocation implements WebSocketCommand {
  double lat;
  double lon;

  @override
  WebSocketMethod method = WebSocketMethod.getAddressFromLocation;

  @override
  bool requiresAuthentication = true;

  @override
  String sessionId;

  GetAddressFromLocation(this.lat, this.lon, this.sessionId);

  Map<String, dynamic> toJson() => {
        'method': WebSocketMethodHelper.getValue(method),
        'sessionId': '$sessionId',
        'lat': lat,
        'lon': lon
      };
}

class RouteStart implements WebSocketCommand {
  @override
  WebSocketMethod method = WebSocketMethod.routeStart;

  @override
  bool requiresAuthentication = true;

  @override
  String sessionId;

  RouteStart(this.sessionId);

  Map<String, dynamic> toJson() => {
        'method': WebSocketMethodHelper.getValue(method),
        'sessionId': '$sessionId'
      };
}

class RouteFinish implements WebSocketCommand {
  @override
  WebSocketMethod method = WebSocketMethod.routeFinish;

  @override
  bool requiresAuthentication = true;

  @override
  String sessionId;

  RouteFinish(this.sessionId);

  Map<String, dynamic> toJson() => {
        'method': WebSocketMethodHelper.getValue(method),
        'sessionId': '$sessionId'
      };
}
