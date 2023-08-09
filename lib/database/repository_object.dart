abstract class RepositoryObject {
  int? get id;

  Map<String, dynamic> toMap();

  copy({int? id});
}
