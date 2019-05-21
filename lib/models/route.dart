import 'package:bike_now/models/sg.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import 'gh_node.dart';
import 'instruction.dart';
import 'lsa.dart';

class Route{
  List<Instruction> instructions;
  double descend;
  double ascend;
  double distance;
  int time;
  int duration;
  DateTime arrivalTime;
  List<LatLng> coordinates;

  List<LSA> getLSAs(){

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