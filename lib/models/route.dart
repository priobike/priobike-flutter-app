import 'package:bike_now/models/sg.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:bike_now/models/latlng.dart';

import 'gh_node.dart';
import 'instruction.dart';
import 'lsa.dart';

part 'route.g.dart';


@JsonSerializable()
class Route{
  List<Instruction> instructions;
  double descend;
  double ascend;
  double distance;
  int time;
  int duration;
  DateTime arrivalTime;
  List<LatLng> coordinates;


  Route(this.instructions, this.descend, this.ascend, this.distance, this.time,
      this.duration, this.arrivalTime, this.coordinates){
    coordinates = [];
    for (var instruction in instructions){
      instruction.nodes.forEach(((node) => coordinates.add(LatLng(node.lat, node.lon))));
    }
    
    arrivalTime = DateTime.now().add(Duration(milliseconds: time));
  }

  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$RouteToJson(this);

  List<LSA> getLSAs(){
    List<LSA> result = [];
    instructions.forEach((inst) => inst.lsas.forEach((lsa) => result.add(lsa)));
    return result;
  }

  Map<int,LSA> getLSADictionary(){

  }

  List<SG> getSGs(){

  }

  List<GHNode> getGHNodes(){

  }

  GHNode getNextGHNode(){

  }

  bool hasGHNodes(){

  }

  GHNode getFirstGHNode(){

  }

  GHNode getLastGHNode(){

  }



}