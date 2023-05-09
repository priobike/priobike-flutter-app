class Article {
  /// The title of the article.
  final String title;

  /// The subtitle of the article.
  final String subtitle;

  /// The estimated time to read the article.
  final String estimatedTime;

  /// The image source of the article.
  final String image;

  /// The paragraphs of the article.
  final List<String> paragraphs;

  Article(this.title, this.subtitle, this.estimatedTime, this.image,
      this.paragraphs);

  factory Article.fromJson(Map<String, dynamic> json) => Article(
      json['title'],
      json['subtitle'],
      json["estimatedTime"],
      json["image"],
      (json['paragraphs'] as List).map((e) => e as String).toList());

  /// Convert the waypoint to a json map.
  Map<String, dynamic> toJSON() => {
        "title": title,
        "subTitle": subtitle,
        "estimatedTime": estimatedTime,
        "image": image,
        "paragraphs": paragraphs,
      };
}
