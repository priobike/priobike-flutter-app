import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service which manages the gamification intro views.
class GameIntroService with ChangeNotifier {
  /// The key under which the information if the user has started the intro is stored in shared preferences.
  static const startedIntroKey = "priobike.game.intro.started";

  /// Bool which determines wether the shared preferences have been loaded
  bool _loadedValues = false;

  bool get loadedValues => _loadedValues;

  /// Bool which determines wether the user has started the game intro.
  bool _startedIntro = false;

  bool get startedIntro => _startedIntro;

  /// Shared preferences instance to store and retrieve at which point of the intro the user is.
  SharedPreferences? _prefs;

  GameIntroService() {
    _loadValues();
  }

  /// To be called when the intro has been started by the user. Sets the corresponding value to true and
  /// stores it in the shared preferences
  void startIntro() {
    _startedIntro = true;
    _prefs?.setBool(startedIntroKey, _startedIntro);
    notifyListeners();
  }

  void confirmPreferences() {
    notifyListeners();
  }

  /// Load values from shared preferences.
  void _loadValues() async {
    _prefs = await SharedPreferences.getInstance();
    _startedIntro = _prefs?.getBool(startedIntroKey) ?? false;
    _loadedValues = true;
    notifyListeners();
  }
}
