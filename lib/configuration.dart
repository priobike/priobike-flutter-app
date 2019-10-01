import 'package:uuid/uuid.dart';

class Configuration {
  static String apiKey = "lIxl5mZhbwVzli1c";
  static String sessionUUID = Uuid().v4().replaceAll("-", "");
  static double userMaxSpeed = 25.0;
}

class SettingKeys {
  static String isSimulator = "isSimulator";
  static String isLocationPush = "isLocationPush";
}
