class AuthRequest {
  String? clientId;

  AuthRequest({this.clientId});

  AuthRequest.fromJson(Map<String, dynamic> json) {
    clientId = json['clientId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['clientId'] = clientId;
    return data;
  }
}
