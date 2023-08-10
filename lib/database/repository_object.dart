/// Abstract class for objects managed by a corresponding [Repository].
abstract class RepositoryObject {
  int? get id;

  Map<String, dynamic> toMap();

  copyWithId({int? id});
}
