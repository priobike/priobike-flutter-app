class Audioquestions {
  /// The optinal scores of the answers, if provided. Max length: 10.
  final List<int> susAnswers;

  /// The optional value of the comment, if provided.
  final String comment;

  const Audioquestions({
    required this.susAnswers,
    required this.comment,
  });
}
