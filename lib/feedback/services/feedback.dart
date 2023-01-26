import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:priobike/feedback/messages/answer.dart';
import 'package:priobike/feedback/models/question.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/user.dart';
import 'package:provider/provider.dart';

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
  Future<bool> send(BuildContext context) async {
    if (!willSendFeedback) return false;

    isSendingFeedback = true;
    notifyListeners();

    final sessionId = Provider.of<Ride>(context, listen: false).sessionId;
    final userId = await User.getOrCreateId();

    // Send all of the answered questions to the backend.
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;
    final endpoint = Uri.parse('https://$baseUrl/feedback-service/answers/post/');
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
      } on TimeoutException catch (error) {
        log.w("Timeout sending feedback to $endpoint: $error");
      } on SocketException catch (error) {
        log.w("Error sending feedback to $endpoint: $error");
      }
    }

    pending = {};
    isSendingFeedback = false;
    notifyListeners();

    return true;
  }
}
