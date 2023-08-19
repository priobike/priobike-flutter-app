import 'package:flutter/material.dart';
import 'package:priobike/gamification/hub/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameSettingsService with ChangeNotifier {
  static const gameFeatureStatisticsKey = 'priobike.game.features.statistics';

  static Map<String, String> get gameFeaturesLabelMap => {
        gameFeatureStatisticsKey: 'Fahrtstatistiken anzeigen',
      };

  SharedPreferences? _prefs;

  /// List of the selected game preferences of the user as string keys.
  List<String> _enabledFeatures = [];
  List<String> get enabledFeatures => _enabledFeatures;

  GameSettingsService() {
    _loadEnabledFeatures();
  }

  void _loadEnabledFeatures() async {
    _prefs ??= await SharedPreferences.getInstance();
    _enabledFeatures = _prefs!.getStringList(UserProfileService.userPreferencesKey) ?? [];
  }

  /// Returns true, if a given string key is inside of the list of selected game prefs.
  bool isFeatureEnabled(String key) => _enabledFeatures.contains(key);

  /// Removes a key out of the enabled feature, if the key is inside the lits. Otherwise adds it to the list.
  void enableOrDisableFeature(String key) async {
    if (_enabledFeatures.contains(key)) {
      _enabledFeatures.remove(key);
    } else {
      _enabledFeatures.add(key);
    }
    _prefs ??= await SharedPreferences.getInstance();
    _prefs!.setStringList(UserProfileService.userPreferencesKey, _enabledFeatures);
    notifyListeners();
  }
}
