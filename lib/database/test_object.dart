import 'package:json_annotation/json_annotation.dart';
import 'package:priobike/database/repository_object.dart';

part 'test_object.g.dart';

@JsonSerializable()
class TestObject extends RepositoryObject {
  int? _id;
  final int number;

  TestObject(this.number);

  @override
  copyWithId({int? id}) {
    _id = id;
    return this;
  }

  @override
  int? get id => _id;

  /// Transform the object to a map.
  @override
  Map<String, dynamic> toMap() => _$TestObjectToJson(this);

  /// Create an object from a map.
  factory TestObject.fromJson(Map<String, dynamic> json) => _$TestObjectFromJson(json);
}
