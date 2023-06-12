enum TestType {
  wearVibrationInterval,
  wearVibrationContinuous,
  wearAudioInterval,
  wearAudioContinuous,
  phoneVibrationInterval,
  phoneVibrationContinuous,
  phoneAudioInterval,
  phoneAudioContinuous,
}

extension TestTypeDescription on TestType {
  String get description {
    switch (this) {
      case TestType.wearVibrationInterval:
        return "Wear Vibration Interval";
      case TestType.wearVibrationContinuous:
        return "Wear Vibration Continuous";
      case TestType.wearAudioInterval:
        return "Wear Audio Interval";
      case TestType.wearAudioContinuous:
        return "Wear Audio Continuous";
      case TestType.phoneVibrationInterval:
        return "Phone Vibration Interval";
      case TestType.phoneVibrationContinuous:
        return "Phone Vibration Continuous";
      case TestType.phoneAudioInterval:
        return "Phone Audio Interval";
      case TestType.phoneAudioContinuous:
        return "Phone Audio Continuous";
    }
  }
}

enum InputType {
  faster,
  slower,
}

extension InputTypeDescription on InputType {
  String get description {
    switch (this) {
      case InputType.faster:
        return "Faster";
      case InputType.slower:
        return "Slower";
    }
  }
}

class Test {
  /// The user.
  final String user;

  /// The testType.
  final TestType testType;

  /// The date.
  final String date;

  final List<TestData> inputs;

  final List<TestData> outputs;

  const Test(
      {required this.user,
      required this.testType,
      required this.date,
      required this.inputs,
      required this.outputs});

  Map<String, dynamic> toJson() => {
        'user': user,
        'testType': testType.description,
        'date': date,
        'inputs': inputs.map((e) => e.toJson()).toList(),
        'outputs': outputs.map((e) => e.toJson()).toList(),
      };

  factory Test.fromJson(dynamic json) => Test(
        user: json["user"],
        testType: TestType.values.firstWhere((element) => element.description == json["testType"]),
        date: json["date"],
        inputs:
            (json["inputs"] as List).map((e) => TestData.fromJson(e)).toList(),
        outputs:
            (json["outputs"] as List).map((e) => TestData.fromJson(e)).toList(),
      );
}

class TestData {
  /// Type
  final InputType inputType;

  /// Timestamp
  final String timestamp;

  /// Lat
  final double lat;

  /// Lon
  final double lon;

  TestData({
    required this.inputType,
    required this.timestamp,
    required this.lat,
    required this.lon,
  });

  Map<String, dynamic> toJson() => {
        'inputType': inputType.description,
        'timestamp': timestamp,
        'lat': lat,
        'lon': lon,
      };

  factory TestData.fromJson(dynamic json) => TestData(
        inputType: InputType.values.firstWhere((element) => element.description == json["inputType"]),
        timestamp: json["timestamp"],
        lat: json["lat"],
        lon: json["lon"],
      );
}
