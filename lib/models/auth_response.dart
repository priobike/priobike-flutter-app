class AuthResponse {
  String? sessionId;

  AuthResponse({this.sessionId});

  AuthResponse.fromJson(Map<String, dynamic> json) {
    sessionId = json['sessionId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sessionId'] = sessionId;
    return data;
  }
}
