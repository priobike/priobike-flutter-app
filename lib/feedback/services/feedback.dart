

import 'package:flutter/material.dart';
import 'package:priobike/feedback/models/question.dart';

class FeedbackService with ChangeNotifier {
  /// The pending questions by their question ids.
  Map<String, Question> pending = {};

  /// Update a question by the question id.
  Future<void> update({required String id, required Question question}) async {
    pending[id] = question;
    notifyListeners();
  }

  /// Reset the feedback service.
  Future<void> reset() async {
    pending = {};
    notifyListeners();
  }
}