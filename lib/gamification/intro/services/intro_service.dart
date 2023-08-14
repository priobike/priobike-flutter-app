import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service which manages the gamification intro views.
class GameIntroService with ChangeNotifier {
  static const prefKeyTest1 = "priobike.game.prefs.test1";
  static const prefKeyTest2 = "priobike.game.prefs.test2";
  static const prefKeyTest3 = "priobike.game.prefs.test3";
  static const prefKeyTest4 = "priobike.game.prefs.test4";
  static const prefKeyTest5 = "priobike.game.prefs.test5";
  static const prefKeyTest6 = "priobike.game.prefs.test6";

  /// The key under which the information if the user has started the intro is stored in shared preferences.
  static const finishedTutorialKey = "priobike.game.finishedTutorial";

  /// Shared preferences instance to store and retrieve at which point of the intro the user is.
  SharedPreferences? _prefs;

  bool pageChanged = false;

  /// Bool which determines wether the shared preferences have been loaded
  bool _loadedValues = false;

  bool get loadedValues => _loadedValues;

  /// Bool which determines wether the user has started the game intro.
  bool _startedIntro = false;

  bool get startedIntro => _startedIntro;

  bool _prefsSet = false;

  bool get prefsSet => _prefsSet;

  bool _tutorialFinished = false;

  bool get tutoralFinished => _tutorialFinished;

  String _username = "";

  String get username => _username;

  void setUsername(String value) {
    _username = value;
    notifyListeners();
  }

  void setTutorialFinished(bool value) {
    _tutorialFinished = value;
    _prefs?.setBool(finishedTutorialKey, _tutorialFinished);
    notifyListeners();
  }

  void setStartedIntro(bool value) {
    _startedIntro = value;
    pageChanged = true;
    notifyListeners();
  }

  final List<String> _gamePrefs = [];

  bool stringInPrefs(String value) => _gamePrefs.contains(value);

  void addOrRemoveFromPrefs(String pref) {
    if (_gamePrefs.contains(pref)) {
      _gamePrefs.remove(pref);
    } else {
      _gamePrefs.add(pref);
    }
    notifyListeners();
  }

  GameIntroService() {
    _loadValues();
  }

  void setPrefsSet(bool value) {
    _prefsSet = value;
    pageChanged = true;
    notifyListeners();
  }

  /// Load values from shared preferences.
  void _loadValues() async {
    _prefs = await SharedPreferences.getInstance();
    _loadedValues = true;
    notifyListeners();
  }
}
