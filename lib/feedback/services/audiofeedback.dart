import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/feedback/messages/audioanswer.dart';
import 'package:priobike/feedback/models/audioquestions.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/user.dart';

class Audiofeedback with ChangeNotifier {
  final log = Logger("Audiofeedback");

  /// The pending questions by a unique identifier.
  Map<String, Audioquestions> pending = {};

  /// A boolean indicating if the audiofeedback service is sending audiofeedback.
  var isSendingAudiofeedback = false;

  /// A boolean indicating if the audiofeedback service will send audiofeedback.
  get willSendAudiofeedback => pending.isNotEmpty;

  /// Update a audioquestion by the audioquestion id.
  Future<void> update({required String id, required Audioquestions audioquestion}) async {
    pending[id] = audioquestion;
    notifyListeners();
  }

  /// Reset the audiofeedback service.
  Future<void> reset() async {
    pending = {};
    isSendingAudiofeedback = false;
    notifyListeners();
  }

  /// Send an answered audioquestion.
  Future<bool> send() async {
    if (!willSendAudiofeedback) {
      // Send an empty result if there are no pending answers to track the audio usage.
      const audioquestions = Audioquestions(
        susAnswers: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        comment: "",
      );
      update(id: "Audiofeedback", audioquestion: audioquestions);
    }

    isSendingAudiofeedback = true;
    notifyListeners();

    final sessionId = getIt<Ride>().sessionId ?? "";
    final userId = await User.getOrCreateId();
    final trackId = getIt<Tracking>().track?.sessionId ?? "";

    // Send all of the answered audioquestions to the backend.
    final endpoint =
        Uri.parse('https://priobike.vkw.tu-dresden.de/staging/audio-evaluation-service/answers/send-answer');
    for (final entry in pending.values.toList().asMap().entries) {
      final request = PostAudioAnswerRequest(
        userId: userId,
        sessionId: sessionId,
        trackId: trackId,
        susAnswers: entry.value.susAnswers,
        comment: entry.value.comment,
      );

      try {
        final response =
            await Http.post(endpoint, body: jsonEncode(request.toJson())).timeout(const Duration(seconds: 4));
        if (response.statusCode != 200) {
          log.e("Error sending audiofeedback to $endpoint: ${response.body}");
        } else {
          log.i("Sent audiofeedback to $endpoint (${entry.key + 1}/${pending.length})");
        }
      } catch (error) {
        final hint = "Error sending audiofeedback to $endpoint: $error";
        log.e(hint);
      }
    }

    pending = {};
    isSendingAudiofeedback = false;
    notifyListeners();

    return true;
  }
}
