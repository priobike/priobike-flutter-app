import 'package:bike_now_flutter/configuration.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingService{

  // Make this a singleton class.
  SettingService._privateConstructor();
  static final SettingService instance = SettingService._privateConstructor();

  Future<bool> get isLocationPush async{
    var pref = await SharedPreferences.getInstance();
    return pref.get(SettingKeys.isLocationPush);
  }
  Future<bool> get isSimulator async{
    var pref = await SharedPreferences.getInstance();
    return pref.get(SettingKeys.isSimulator);
  }
}