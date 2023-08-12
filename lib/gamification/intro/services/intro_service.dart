import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameIntroService with ChangeNotifier {
  /// The key under which ... user defaults / shared preferences.
  static const startedIntroKey = "priobike.game.intro.started";

  bool _loadedValues = false;

  bool get loadedValues => _loadedValues;

  bool _startedIntro = false;

  bool get startedIntro => _startedIntro;

  SharedPreferences? _prefs;

  GameIntroService() {
    _loadValues();
  }

  void startIntro() {
    _startedIntro = true;
    _prefs?.setBool(startedIntroKey, true);
    notifyListeners();
  }

  void _loadValues() async {
    _prefs = await SharedPreferences.getInstance();
    _startedIntro = _prefs?.getBool(startedIntroKey) ?? false;
    _loadedValues = true;
    notifyListeners();
  }
}
