import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/routing/models/sg.dart';

class SelectRideRequest {
  /// The session id.
  final String sessionId;

  /// The selected route of the ride.
  final List<NavigationNode> route;

  /// The selected navigation path of the ride.
  final GHRouteResponsePath navigationPath;

  /// The selected signal groups for the ride, mapped by their id.
  final Map<String, Sg> signalGroups;

  const SelectRideRequest({
    required this.sessionId,
    required this.route,
    required this.navigationPath,
    required this.signalGroups,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['sessionId'] = sessionId;
    data['route'] = route.map((e) => e.toJson()).toList();
    data['navigationPath'] = navigationPath.toJson();
    data['signalGroups'] = { for (var e in signalGroups.entries) e.key : e.value.toJson() };
    return data;
  }
}

class SelectRideResponse {
  /// If the selection was successful.
  final bool success;

  const SelectRideResponse({
    required this.success,
  });

  factory SelectRideResponse.fromJson(Map<String, dynamic> json) {
    return SelectRideResponse(success: json['success']);
  }
}
