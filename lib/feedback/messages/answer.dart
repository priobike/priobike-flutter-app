class PostAnswerRequest {
  /// The id of the device. Max length: 100.
  final String userId;

  /// The text of the question. Max length: 300.
  final String questionText;

  /// The base 64 encoded image of this question, if provided. Max length: 10MB.
  final String? questionImage;

  /// The id of the session, if provided. Max length: 100.
  final String? sessionId;

  /// The value of the answer, if provided. Max length: 1000
  final String? value;

  const PostAnswerRequest({
    required this.userId,
    required this.questionText,
    this.questionImage,
    this.sessionId,
    this.value,
  });

  factory PostAnswerRequest.fromJson(Map<String, dynamic> json) => PostAnswerRequest(
        userId: json['userId'],
        questionText: json['questionText'],
        questionImage: json['questionImage'],
        sessionId: json['sessionId'],
        value: json['value'],
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'questionText': questionText,
        if (questionImage != null) 'questionImage': questionImage,
        if (sessionId != null) 'sessionId': sessionId,
        if (value != null) 'value': value,
      };
}

class PostAnswerResponse {
  final bool? success;

  const PostAnswerResponse({this.success});

  factory PostAnswerResponse.fromJson(Map<String, dynamic> json) {
    return PostAnswerResponse(success: json['success']);
  }

  Map<String, dynamic> toJson() => {
        'success': success,
      };
}
