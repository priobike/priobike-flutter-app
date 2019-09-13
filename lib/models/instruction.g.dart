// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instruction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Instruction _$InstructionFromJson(Map<String, dynamic> json) {
  return Instruction(
      json['sign'] as int,
      json['name'] as String,
      json['text'] as String,
      json['info'] as String,
      (json['lsaArray'] as List)
          ?.map(
              (e) => e == null ? null : LSA.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      (json['nodeArray'] as List)
          ?.map((e) =>
              e == null ? null : GHNode.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      (json['dist'] as num)?.toDouble());
}

Map<String, dynamic> _$InstructionToJson(Instruction instance) =>
    <String, dynamic>{
      'sign': instance.sign,
      'name': instance.name,
      'text': instance.text,
      'info': instance.info,
      'lsaArray': instance.lsas,
      'nodeArray': instance.nodes,
      'dist': instance.distance
    };
