import 'package:bike_now_flutter/helper/settingKeys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingService {
  // Make this a singleton class.
  SettingService._privateConstructor();
  static final SettingService instance = SettingService._privateConstructor();

  bool isLocationPush = false;
  bool isSimulation = false;
  bool isOnboardingComplete = false;

  Future<bool> get loadLocationPush async {
    var pref = await SharedPreferences.getInstance();
    return pref.get(SettingKeys.isLocationPush);
  }

  Future<bool> get loadSimulator async {
    var pref = await SharedPreferences.getInstance();
    return pref.get(SettingKeys.isSimulator);
  }

  Future<bool> get loadOnboardingComplete async {
    var pref = await SharedPreferences.getInstance();
    return pref.get(SettingKeys.onboardingComplete);
  }
}
