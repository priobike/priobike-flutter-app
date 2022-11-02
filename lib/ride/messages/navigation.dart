class NavigationRequest {
  final bool? active;

  const NavigationRequest({this.active});

  factory NavigationRequest.fromJson(Map<String, dynamic> json) {
    return NavigationRequest(
      active: json['active'],
    );
  }

  Map<String, dynamic> toJson() => {'active': active};
}
