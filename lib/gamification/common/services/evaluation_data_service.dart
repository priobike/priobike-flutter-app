import 'package:priobike/gamification/common/models/evaluation_data.dart';
import 'package:priobike/http.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// This service handles sending data relevant for the evaluation of the gamification functionality to the backend.
class EvaluationDataService {
  /// Shared prefs key to store unsent elements.
  static const String unsentElementsKey = 'priobike.gamification.evaluation.unsentElements';

  static const int dataSendingAttempsThreshold = 5;

  String get baseUrl => 'https://${getIt<Settings>().backend.path}/game-service/';

  /// List of unsent elements.
  List<EvaluationData> unsentElements = [];

  /// Send a given json map to a given address of the gamification service.
  Future<void> sendJsonToAddress(String address, Map<String, dynamic> jsonData) async {
    // Add user id and timestamp to the data and create a data object.
    final userId = await User.getOrCreateId();
    jsonData.addAll({'userId': userId, 'timestamp': DateTime.now().millisecondsSinceEpoch});
    var data = EvaluationData(address, jsonData);
    // Try to send data to service.
    var success = await sendEvaluationData(data);
    if (success) return;
    // If sending was not successful, store the object in the list of unsent elements.
    data.numOfAttemps = 1;
    unsentElements.add(data);
    var prefs = await SharedPreferences.getInstance();
    prefs.setStringList(unsentElementsKey, unsentElements.map((e) => e.toJson()).toList());
    log.e('Saved unsent message: ${data.toJson()}');
  }

  /// Try to send all elements from the list of unsent elements to the service.
  Future<void> sendUnsentElements() async {
    var prefs = await SharedPreferences.getInstance();
    var tmpList = prefs.getStringList(unsentElementsKey)?.map((e) => EvaluationData.fromJson(e)).toList() ?? [];
    for (var element in tmpList) {
      var success = await sendEvaluationData(element);
      if (success) continue;
      element.numOfAttemps += 1;
      if (element.numOfAttemps >= dataSendingAttempsThreshold) continue;
      unsentElements.add(element);
      log.i('Saved unsent message: ${element.toJson()}');
    }

    /// Store elements that still couldn't be sent in the shared prefs.
    prefs.setStringList(unsentElementsKey, unsentElements.map((e) => e.toJson()).toList());
  }

  /// Send the data in a given evaluation data object to the corresponding address of the gamification service.
  Future<bool> sendEvaluationData(EvaluationData data) async {
    try {
      // Build and parse url to send to.
      final postUrl = "$baseUrl${data.address}";
      final postProfileEndpoint = Uri.parse(postUrl);

      log.i("Sending gamification data to $postUrl");

      // Try to send json data to url of the gamification service.
      final response = await Http.post(postProfileEndpoint, body: data.jsonData).timeout(const Duration(seconds: 4));

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
