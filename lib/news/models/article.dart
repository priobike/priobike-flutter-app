/// News-article object
class Article {
  /// Primary key of the article
  final int id;

  /// Body of the article
  final String text;

  /// Title of the article
  final String title;

  /// Publication date of the article
  final DateTime pubDate;

  /// Category of the article
  final int? categoryId;

  /// MD5 hash of the article
  final String md5;

  const Article(
      {required this.id,
      required this.text,
      required this.title,
      required this.pubDate,
      required this.categoryId,
      required this.md5});

  /// Returns an article given a [json] representation of an article.
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json["id"],
      text: json["text"],
      title: json['title'],
      pubDate: DateTime.parse(json['pub_date']),
      categoryId: json['category_id'],
      md5: json['md5'],
    );
  }

  /// Returns a json representation of the article object calling this method.
  Map<String, Object?> toJson() =>
      {'id': id, 'title': title, 'text': text, 'pub_date': pubDate.toString(), 'category_id': categoryId, 'md5': md5};

  @override
  int get hashCode => md5.hashCode;

  @override
  bool operator ==(Object other) {
    return other is Article && other.md5 == md5;
  }
}
