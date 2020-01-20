import 'dart:convert';

import 'package:bikenow/models/gateway_status.dart';
import 'package:http/http.dart' as http;
import 'package:bikenow/models/route_answer.dart';

class Api {
  static const API_KEY = 'lIxl5mZhbwVzli1c';
  static const HOST = 'http://vkwvlprad.vkw.tu-dresden.de';
  static const PORT = '20043';

  static Future<RouteAnswer> getRoute(fromLat, fromLon, toLat, toLon) async {
    var response = await http.get(
        '$HOST:$PORT/getRoute?fromLat=$fromLat&fromLon=$fromLon&toLat=$toLat&toLon=$toLon&key=$API_KEY');
    return RouteAnswer.fromJson(json.decode(response.body));
  }

  static Future<GatewayStatus> getStatus() async {
    var response = await http.get('$HOST:$PORT/status');
    return GatewayStatus.fromJson(json.decode(response.body));
  }
}
