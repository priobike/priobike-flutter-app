class NavigationRequest {
  final bool? active;

  const NavigationRequest({this.active});

  factory NavigationRequest.fromJson(Map<String, dynamic> json) {
    return NavigationRequest(
      active: json['active'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['active'] = active;
    return data;
  }
}
