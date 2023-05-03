class Article {
  /// The title of the article.
  final String title;

  /// The subTitle of the article.
  final String subTitle;

  /// The image source of the article.
  final String image;

  /// The paragraphs of the article.
  final List<String> paragraphs;

  Article(this.title, this.subTitle, this.image, this.paragraphs);

  factory Article.fromJson(Map<String, dynamic> json) => Article(
      json['title'], json['subTitle'], json["image"], (json['paragraphs'] as List).map((e) => e as String).toList());

  /// Convert the waypoint to a json map.
  Map<String, dynamic> toJSON() => {
        "title": title,
        "subTitle": subTitle,
        "image": image,
        "paragraphs": paragraphs,
      };
}
