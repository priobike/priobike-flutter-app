// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) {
  return Subscription(
      json['lsaId'] as int,
      json['lsaName'] as String,
      (json['sgArray'] as List)
          ?.map((e) => e == null
              ? null
              : SGSubscription.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$SubscriptionToJson(Subscription instance) =>
    <String, dynamic>{
      'lsaId': instance.lsaId,
      'lsaName': instance.lsaName,
      'sgArray': instance.sgArray
    };
