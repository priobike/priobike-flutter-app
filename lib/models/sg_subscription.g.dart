// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sg_subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SGSubscription _$SGSubscriptionFromJson(Map<String, dynamic> json) {
  return SGSubscription(json['sgName'] as String, json['status'] as bool);
}

Map<String, dynamic> _$SGSubscriptionToJson(SGSubscription instance) =>
    <String, dynamic>{'sgName': instance.sgName, 'status': instance.status};
