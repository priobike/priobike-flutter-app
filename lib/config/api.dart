import 'dart:convert';

import 'package:priobike/models/api/api_pilotstrecken.dart';
import 'package:priobike/models/api/api_status.dart';
import 'package:http/http.dart' as http;

import 'config.dart';

class Api {

  static Future<ApiStatus> getStatus() async {
    var response = await http.get('${Config.GATEWAY_URL}:${Config.GATEWAY_PORT}/status');
    return ApiStatus.fromJson(json.decode(response.body));
  }

  static Future<ApiPilotstrecken> getPilotstrecken() async {
    var response = await http.get('${Config.GATEWAY_URL}:${Config.GATEWAY_PORT}/pilotstrecken?key=${Config.GATEWAY_API_KEY}');
    return ApiPilotstrecken.fromJson(json.decode(response.body));
  }
}

// http://vkwvlprad.vkw.tu-dresden.de:20043/getRoute?fromLat=51.030815&fromLon=13.726988&toLat=51.068019&toLon=13.753166&key=lIxl5mZhbwVzli1c
