import 'package:json_annotation/json_annotation.dart';

part 'sg_subscription.g.dart';

@JsonSerializable()
class SGSubscription{
  String sgName;
  bool status;

  SGSubscription(this.sgName, this.status);

  factory SGSubscription.fromJson(Map<String, dynamic> json) => _$SGSubscriptionFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$SGSubscriptionToJson(this);
}