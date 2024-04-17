class AudioQuestions {
  /// The scores of the answers, if provided. Max length: 10.
  final List<int> susAnswers;

  /// The value of the comment, if provided.
  final String comment;

  const AudioQuestions({
    required this.susAnswers,
    required this.comment,
  });
}
