import 'dart:convert';

import 'package:bikenow/models/api/api_pilotstrecken.dart';
import 'package:bikenow/models/api/api_status.dart';
import 'package:http/http.dart' as http;
import 'package:bikenow/models/api/api_route.dart';

class Api {
  static const API_KEY = 'lIxl5mZhbwVzli1c';
  static const HOST = 'http://bikenow.vkw.tu-dresden.de';
  static const PORT = '20043';

  static Future<ApiRoute> getRoute(fromLat, fromLon, toLat, toLon, id) async {

    print('$HOST:$PORT/getRoute?fromLat=$fromLat&fromLon=$fromLon&toLat=$toLat&toLon=$toLon&id=$id&key=$API_KEY');

    var response = await http.get(
        '$HOST:$PORT/getRoute?fromLat=$fromLat&fromLon=$fromLon&toLat=$toLat&toLon=$toLon&id=$id&key=$API_KEY');
    return ApiRoute.fromJson(json.decode(response.body));
  }

  static Future<ApiStatus> getStatus() async {
    var response = await http.get('$HOST:$PORT/status');
    return ApiStatus.fromJson(json.decode(response.body));
  }

  static Future<ApiPilotstrecken> getPilotstrecken() async {
    var response = await http.get('$HOST:$PORT/pilotstrecken?key=$API_KEY');
    return ApiPilotstrecken.fromJson(json.decode(response.body));
  }
}

// http://vkwvlprad.vkw.tu-dresden.de:20043/getRoute?fromLat=51.030815&fromLon=13.726988&toLat=51.068019&toLon=13.753166&key=lIxl5mZhbwVzli1c