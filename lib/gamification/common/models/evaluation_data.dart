import 'dart:convert';

/// This objects holds data which needs to be send to the gamification service.
class EvaluationData {
  /// The url address to send the data to.
  final String address;

  /// The data as an encoded json String.
  final String jsonData;

  /// Number of attemps of sending this data object to the backend.
  int numOfAttemps = 0;

  EvaluationData(this.address, Map<String, dynamic> map) : jsonData = json.encode(map);

  String toJson() => json.encode({'address': address, 'jsonData': jsonData, 'numOfAttemps': numOfAttemps});

  EvaluationData.fromJson(String encoded)
      : address = json.decode(encoded)['address'],
        jsonData = json.decode(encoded)['jsonData'],
        numOfAttemps = json.decode(encoded)['numOfAttemps'];
}
