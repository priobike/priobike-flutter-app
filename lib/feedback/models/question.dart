import 'dart:typed_data';

class Question {
  /// The text of the question. Max length: 300.
  final String text;

  /// The optional image data of the question.
  final Uint8List? imageData;

  /// The optional answer to the question.
  final String? answer;

  const Question({
    required this.text,
    this.imageData,
    this.answer,
  });
}