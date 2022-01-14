class NavigationRequest {
  bool? active;

  NavigationRequest({this.active});

  NavigationRequest.fromJson(Map<String, dynamic> json) {
    active = json['active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['active'] = active;
    return data;
  }
}
