import 'package:bike_now/models/sg.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:bike_now/models/latlng.dart';

import 'gh_node.dart';
import 'instruction.dart';
import 'lsa.dart';

part 'route.g.dart';

@JsonSerializable()
class Route {
  List<Instruction> instructions;
  double descend;
  double ascend;
  double distance;
  int time;
  int _duration;

  int get duration {
    return (time / 1000).round();
  }

  DateTime get arrivalTime {
    var now = DateTime.now();
    var then = now.add(Duration(minutes: duration));
    return then;
  }

  set arrivalTime(DateTime value) {
    _arrivalTime = value;
  }

  DateTime _arrivalTime;
  List<LatLng> _coordinates;

  List<LatLng> get coordinates {
    List<LatLng> result = [];
    for (var instruction in instructions) {
      instruction.nodes
          .forEach(((node) => result.add(LatLng(node.lat, node.lon))));
    }
    return result;
  }

  Route(
      this.instructions, this.descend, this.ascend, this.distance, this.time) {}

  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$RouteToJson(this);

  List<LSA> getLSAs() {
    List<LSA> result = [];
    instructions.forEach((inst) => inst.lsas.forEach((lsa) => result.add(lsa)));
    return result;
  }

  Map<int, LSA> getLSADictionary() {
    List<LSA> lsas = getLSAs();
    Map<int, LSA> dictionary = Map<int, LSA>();

    lsas.forEach((lsa) {
      if (dictionary.containsKey(lsa.id)) {
        lsa.sgs.forEach((sg) => dictionary[lsa.id].sgs.add(sg));
      } else {
        dictionary[lsa.id] = lsa;
      }
    });
    return dictionary;
  }

  List<SG> getSGs() {
    List<SG> result = [];
    getLSAs().forEach((lsa) {
      lsa.sgs.forEach((sg) {
        result.add(sg);
      });
    });
  }

  List<GHNode> getGHNodes(bool withVirtualNodes) {
    List<GHNode> result = [];
    instructions.forEach((instruction) {
      instruction.nodes.forEach((node) {
        if (node.id != null && node.id >= 0 || withVirtualNodes) {
          result.add(node);
        }
      });
    });
    return result;
  }

  GHNode getNextGHNode(List<GHNode> ghNodes,
      [double minDistance = 5, bool virtualNode = true]) {
    var list = ghNodes.where((ghNode) {
      return !ghNode.isCrossed && ghNode.distance >= minDistance;
    }).toList();

    var ghNode = list.firstWhere((ghNode) {
      if (virtualNode || ghNode.id != null) {
        return true;
      }
      return false;
    });

    return ghNode;
  }

  bool hasGHNodes(bool withVirtualNodes) {
    return getGHNodes(withVirtualNodes).length > 1;
  }

  GHNode getFirstGHNode() {
    return instructions.first.nodes.first;
  }

  GHNode getLastGHNode() {
    return instructions.last.nodes.last;
  }
}
