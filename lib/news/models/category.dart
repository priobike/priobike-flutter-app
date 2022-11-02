/// Category of news articles.
class Category {
  /// Primary key of the category
  final int id;

  /// Title of the category
  final String title;

  const Category({required this.id, required this.title});

  /// Returns a category given a [json] representation of a category.
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json["id"], title: json["title"]);
  }

  /// Returns a json representation of the category object calling this method.
  Map<String, Object> toJson() => {'id': id, 'title': title};
}
