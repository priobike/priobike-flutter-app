import 'package:priobike/models/navigation_node.dart';
import 'package:priobike/models/sg.dart';

class RouteResponse {
  double distance = 0;
  int estimatedDuration = 0;
  double ascend = 0;
  double descend = 0;
  Map<String, Sg> signalgroups = <String, Sg>{};
  List<NavigationNode> route = List.empty();

  RouteResponse({
    required this.distance,
    required this.estimatedDuration,
    required this.ascend,
    required this.descend,
    required this.route,
    required this.signalgroups,
  });

  RouteResponse.fromJson(Map<String, dynamic> json) {
    distance = json['distance'].toDouble();
    // TODO: Remove fallback to `estimatedArrival` when production contains 
    // priobike-data-model 0.4.+
    estimatedDuration = json['estimatedArrival'] ?? json['estimatedDuration'] ?? 0;
    ascend = json['ascend'].toDouble();
    descend = json['descend'].toDouble();

    route = List<NavigationNode>.empty(growable: true);

    json['route'].forEach((nn) {
      route.add(NavigationNode.fromJson(nn));
    });

    json['signalGroups'].values.forEach((entry) {
      Sg sg = Sg.fromJson(entry);
      signalgroups[sg.id] = sg;
    });
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['distance'] = distance;
    data['estimatedDuration'] = estimatedDuration;
    data['ascend'] = ascend;
    data['descend'] = descend;

    data['route'] = route.map((v) => v.toJson()).toList();

    // data['signalgroups'] = signalgroups.map((v) => v.toJson()).toList();

    return data;
  }
}
