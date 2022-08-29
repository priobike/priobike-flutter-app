import 'package:flutter/material.dart';

class Question {
  /// The text of the question. Max length: 300.
  final String questionText;

  /// The optional image of the question.
  final Image? questionImage;

  /// The optional answer to the question.
  final String? answer;

  const Question({
    required this.questionText,
    this.questionImage,
    this.answer,
  });
}