class PostAudioAnswerRequest {
  /// The id of the device.
  final String userId;

  /// The id of the session, if provided.
  final String? sessionId;

  /// The id of the track, if provided.
  final String? trackId;

  /// The scores of the answers, if provided. Max length: 10.
  final List<int?> susAnswers;

  /// The value of the comment, if provided.
  final String? comment;

  const PostAudioAnswerRequest({
    required this.userId,
    this.sessionId,
    this.trackId,
    required this.susAnswers,
    this.comment,
  });

  factory PostAudioAnswerRequest.fromJson(Map<String, dynamic> json) => PostAudioAnswerRequest(
        userId: json['user_id'],
        sessionId: json['session_id'],
        trackId: json['track_id'],
        susAnswers: List<int?>.from(json['sus_answers']),
        comment: json['comment'],
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        if (sessionId != null) 'session_id': sessionId,
        if (trackId != null) 'track_id': trackId,
        'sus_answers': susAnswers,
        if (comment != null) 'comment': comment,
      };
}

class PostAudioAnswerResponse {
  final bool? success;

  const PostAudioAnswerResponse({this.success});

  factory PostAudioAnswerResponse.fromJson(Map<String, dynamic> json) {
    return PostAudioAnswerResponse(success: json['success']);
  }

  Map<String, dynamic> toJson() => {
        'success': success,
      };
}
