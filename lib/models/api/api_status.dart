class ApiStatus {
  String status;
  String gatewayTime;

  ApiStatus({this.status, this.gatewayTime});

  ApiStatus.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    gatewayTime = json['gatewayTime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['gatewayTime'] = this.gatewayTime;
    return data;
  }
}