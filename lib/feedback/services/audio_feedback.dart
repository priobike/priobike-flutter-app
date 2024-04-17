import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:priobike/feedback/messages/audio_answer.dart';
import 'package:priobike/feedback/models/audio_questions.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/user.dart';

class AudioFeedback with ChangeNotifier {
  final log = Logger("AudioFeedback");

  /// The pending questions by a unique identifier.
  Map<String, AudioQuestions> pending = {};

  /// A boolean indicating if the audio feedback service is sending audio feedback.
  var isSendingAudioFeedback = false;

  /// A boolean indicating if the audio feedback service will send audio feedback.
  get willSendAudioFeedback => pending.isNotEmpty;

  /// Update a audio question by the audio question id.
  Future<void> update({required String id, required AudioQuestions audioQuestion}) async {
    pending[id] = audioQuestion;
    notifyListeners();
  }

  /// Reset the audio feedback service.
  Future<void> reset() async {
    pending = {};
    isSendingAudioFeedback = false;
    notifyListeners();
  }

  /// Send an answered audio question.
  Future<bool> send() async {
    if (!willSendAudioFeedback) {
      // Send an empty result if there are no pending answers to track the audio usage.
      const audioQuestions = AudioQuestions(
        susAnswers: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        comment: "",
      );
      update(id: "AudioFeedback", audioQuestion: audioQuestions);
    }

    isSendingAudioFeedback = true;
    notifyListeners();

    final sessionId = getIt<Ride>().sessionId ?? "";
    final userId = await User.getOrCreateId();
    final trackId = getIt<Tracking>().track?.sessionId ?? "";

    // Send all of the answered audioQuestions to the backend.
    final settings = getIt<Settings>();
    final baseUrl = settings.backend.path;
    final endpoint = Uri.parse('https://$baseUrl/audio-evaluation-service/answers/send-answer');
    for (final entry in pending.values.toList().asMap().entries) {
      final request = PostAudioAnswerRequest(
          userId: userId,
          sessionId: sessionId,
          trackId: trackId,
          susAnswers: entry.value.susAnswers,
          comment: entry.value.comment,
          debug: kDebugMode,
          // TODO implement how to detect driving with screen off.
          driveWithoutScreen: false);

      try {
        final response =
            await Http.post(endpoint, body: jsonEncode(request.toJson())).timeout(const Duration(seconds: 4));
        if (response.statusCode != 200) {
          log.e("Error sending audio feedback to $endpoint: ${response.body}");
        } else {
          log.i("Sent audio feedback to $endpoint (${entry.key + 1}/${pending.length})");
        }
      } catch (error) {
        final hint = "Error sending audio feedback to $endpoint: $error";
        log.e(hint);
      }
    }

    pending = {};
    isSendingAudioFeedback = false;
    notifyListeners();

    return true;
  }
}
