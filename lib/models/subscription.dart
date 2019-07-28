import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'sg_subscription.dart';

part 'subscription.g.dart';

@JsonSerializable()
class Subscription{
  int lsaId;
  String lsaName;
  List<SGSubscription> sgArray;

  Subscription(this.lsaId, this.lsaName, this.sgArray);

  factory Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);

}
