import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:priobike/feedback/messages/answer.dart';
import 'package:priobike/feedback/models/question.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/user.dart';

class Feedback with ChangeNotifier {
  final log = Logger("Feedback");

  /// The pending questions by a unique identifier.
  Map<String, Question> pending = {};

  /// A boolean indicating if the feedback service is sending feedback.
  var isSendingFeedback = false;

  /// A boolean indicating if the feedback service will send feedback.
  get willSendFeedback => pending.isNotEmpty;

  /// Update a question by the question id.
  Future<void> update({required String id, required Question question}) async {
    pending[id] = question;
    notifyListeners();
  }

  /// Reset the feedback service.
  Future<void> reset() async {
    pending = {};
    isSendingFeedback = false;
    notifyListeners();
  }

  /// Send an answered question.
  Future<bool> send() async {
    if (!willSendFeedback) return false;

    isSendingFeedback = true;
    notifyListeners();

    final sessionId = getIt<Ride>().sessionId;
    final userId = await User.getOrCreateId();

    // Send all of the answered questions to the backend.
    final settings = getIt<Settings>();
    final baseUrl = settings.backend.path;
    final endpoint = Uri.parse('https://$baseUrl/tracking-service/answers/post/');
    for (final entry in pending.values.toList().asMap().entries) {
      final request = PostAnswerRequest(
        userId: userId,
        questionText: entry.value.text,
        questionImage: entry.value.imageData != null ? base64Encode(entry.value.imageData!) : null,
        sessionId: sessionId,
        value: entry.value.answer,
      );

      try {
        final response =
            await Http.post(endpoint, body: json.encode(request.toJson())).timeout(const Duration(seconds: 4));
        if (response.statusCode != 200) {
          log.e(
              "Error sending feedback to $endpoint: ${response.body}"); // If feedback gets lost here, it's not a big deal.
        } else {
          log.i("Sent feedback to $endpoint (${entry.key + 1}/${pending.length})");
        }
      } catch (error) {
        final hint = "Error sending feedback to $endpoint: $error";
        log.e(hint);
      }
    }

    pending = {};
    isSendingFeedback = false;
    notifyListeners();

    return true;
  }
}
