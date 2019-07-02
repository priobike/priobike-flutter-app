import 'abstract_classes/locatable.dart';
import 'abstract_classes/crossable.dart';
import 'abstract_classes/locatable_and_crossable.dart';
import 'gh_node.dart';
import 'lsa.dart';
import 'package:json_annotation/json_annotation.dart';

part 'instruction.g.dart';

@JsonSerializable()
class Instruction with LocatableAndCrossable{
  int sign;
  String name;
  String text;
  String info;
  @JsonKey(name: 'lsaArray')
  List<LSA> lsas;
  @JsonKey(name: 'nodeArray')
  List<GHNode> nodes;


  Instruction(this.sign, this.name, this.text, this.info, this.lsas,
      this.nodes);

  factory Instruction.fromJson(Map<String, dynamic> json) => _$InstructionFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$InstructionToJson(this);

  @override
  bool calculateIsCrossed(double distance, double accuracy) {
    // TODO: implement calculateIsCrossed
    return null;
  }

}