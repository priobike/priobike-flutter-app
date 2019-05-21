import 'abstract_classes/locatable.dart';
import 'abstract_classes/crossable.dart';
import 'gh_node.dart';
import 'lsa.dart';

class Instruction with Locatable, Crossable{
  int sign;
  String name;
  String text;
  String info;
  List<LSA> lsas;
  List<GHNode> nodes;

  @override
  bool calculateIsCrossed(double distance, double accuracy) {
    // TODO: implement calculateIsCrossed
    return null;
  }

}