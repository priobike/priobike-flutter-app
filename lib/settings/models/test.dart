enum TestType {
  wearVibration,
  wearAudio,
  phoneVibration,
  phoneAudio,
}

extension TestTypeDescription on TestType {
  String get description {
    switch (this) {
      case TestType.wearVibration:
        return "Wear Vibration";
      case TestType.wearAudio:
        return "Wear Audio";
      case TestType.phoneVibration:
        return "Phone Vibration";
      case TestType.phoneAudio:
        return "Phone Audio";
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
      {required this.user, required this.testType, required this.date, required this.inputs, required this.outputs});

  Map<String, dynamic> toJson() => {
        'user': user,
        'testType': testType,
        'inputs': inputs.map((e) => e.toJson()).toList(),
        'outputs': outputs.map((e) => e.toJson()).toList(),
      };

  factory Test.fromJson(dynamic json) => Test(
        user: json["user"],
        testType: json["testType"],
        date: json["date"],
        inputs: (json["inputs"] as List).map((e) => TestData.fromJson(e)).toList(),
        outputs: (json["outputs"] as List).map((e) => TestData.fromJson(e)).toList(),
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
        'inputType': inputType,
        'timestamp': timestamp,
        'lat': lat,
        'lon': lon,
      };

  factory TestData.fromJson(dynamic json) => TestData(
        inputType: json["inputType"],
        timestamp: json["timestamp"],
        lat: json["lat"],
        lon: json["lon"],
      );
}
