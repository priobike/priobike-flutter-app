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

  /// The imges of the article.
  final List<String> images;

  const Article(
    this.title,
    this.subtitle,
    this.estimatedTime,
    this.image,
    this.paragraphs,
    this.images,
  );
}
