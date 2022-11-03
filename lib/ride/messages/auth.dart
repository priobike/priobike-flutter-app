class AuthRequest {
  final String? clientId;

  const AuthRequest({this.clientId});

  factory AuthRequest.fromJson(Map<String, dynamic> json) => AuthRequest(
        clientId: json['clientId'],
      );

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
      };
}

class AuthResponse {
  final String? sessionId;

  const AuthResponse({this.sessionId});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        sessionId: json['sessionId'],
      );

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
      };
}
