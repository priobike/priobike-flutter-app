import 'dart:convert';

import 'package:priobike/http.dart';
import 'package:priobike/main.dart';
import 'package:priobike/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EvaluationData {
  final String address;

  final String jsonData;

  EvaluationData(this.address, Map<String, dynamic> map) : jsonData = json.encode(map);

  String toJson() => json.encode({'address': address, 'jsonData': jsonData});

  EvaluationData.fromJson(String encoded)
      : address = json.decode(encoded)['address'],
        jsonData = json.decode(encoded)['jsonData'];
}

class EvaluationDataService {
  static const String unsentElementsKey = 'priobike.gamification.evaluation.unsentElements';

  final baseUrl = '10.0.2.2:8000'; //settings.backend.path;

  List<EvaluationData> unsentElements = [];

  Future<void> sendJsonToAddress(String address, Map<String, dynamic> jsonData) async {
    final userId = await User.getOrCreateId();
    jsonData.addAll({'userId': userId, 'timestamp': DateTime.now().millisecondsSinceEpoch});
    var data = EvaluationData(address, jsonData);
    var result = await sendData(data);
    if (!result) {
      unsentElements.add(data);
      var prefs = await SharedPreferences.getInstance();
      prefs.setStringList(unsentElementsKey, unsentElements.map((e) => e.toJson()).toList());
      log.e('Saved unsent message: ${data.toJson()}');
    }
  }

  Future<void> sendUnsentElements() async {
    var prefs = await SharedPreferences.getInstance();
    var tmpList = prefs.getStringList(unsentElementsKey)?.map((e) => EvaluationData.fromJson(e)).toList() ?? [];
    for (var element in tmpList) {
      var result = await sendData(element);
      if (result) continue;
      unsentElements.add(element);
      log.e('Saved unsent message: ${element.toJson()}');
    }
    prefs.setStringList(unsentElementsKey, unsentElements.map((e) => e.toJson()).toList());
  }

  Future<bool> sendData(EvaluationData data) async {
    try {
      //final settings = getIt<Settings>();

      final postUrl = "http://$baseUrl/${data.address}";
      final postProfileEndpoint = Uri.parse(postUrl);

      log.i("Sending gamification data to $postUrl");

      final response = await Http.post(postProfileEndpoint, body: data.jsonData);

      if (response.statusCode == 200) {
        log.i("Sending of gamification data successful: $postUrl");
        return true;
      } else {
        log.e("Failed to send gamification data: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      final hint = "Failed to load gamification service response: $e";
      log.e(hint);
    }
    return false;
  }
}
