import 'package:flutter/material.dart';
import 'package:priobike/gamification/hub/services/game_service.dart';
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

  /// This variable is set true by a page of the game intro, if it has been finished.
  bool pageChanged = false;

  /// Bool which is true when the shared preferences have been loaded
  bool _loadedValues = false;

  bool get loadedValues => _loadedValues;

  /// Bool which is true when the user has started the game intro.
  bool _startedIntro = false;

  bool get startedIntro => _startedIntro;

  void setStartedIntro(bool value) {
    _startedIntro = value;
    pageChanged = true;
    notifyListeners();
  }

  /// Bool which is true, when the user has entered and confirms game preferences.
  bool _prefsSet = false;

  bool get prefsSet => _prefsSet;

  void setPrefsSet(bool value) {
    _prefsSet = value;
    pageChanged = true;
    notifyListeners();
  }

  /// String which holds the username entered by the user in the corresponding intro page.
  String _username = "";

  String get username => _username;

  void setUsername(String value) {
    _username = value;
    notifyListeners();
  }

  /// Bool which is true, when the user finished the tutorial.
  bool _tutorialFinished = false;

  bool get tutoralFinished => _tutorialFinished;

  /// Set the tutorial as finished in the shared prefs and also store the selected game prefs there.
  void finishTutorial() {
    _tutorialFinished = true;
    _prefs?.setBool(finishedTutorialKey, _tutorialFinished);
    _prefs?.setStringList(GameService.userPreferencesKey, _gamePrefs);
    pageChanged = true;
    notifyListeners();
  }

  /// List of the selected game preferences of the user as string keys.
  final List<String> _gamePrefs = [];

  /// Returns true, if a given string key is inside of the list of selected game prefs.
  bool stringInPrefs(String key) => _gamePrefs.contains(key);

  /// Removes a key out of the user game prefs, if the key is inside the lits. Otherwise adds it to the list.
  void addOrRemoveFromPrefs(String key) {
    if (_gamePrefs.contains(key)) {
      _gamePrefs.remove(key);
    } else {
      _gamePrefs.add(key);
    }
    notifyListeners();
  }

  /// Basic constructor which loads the shared preferences and the relevant values.
  GameIntroService() {
    _loadValues();
  }

  /// Get instance of shared preferences and load values.
  void _loadValues() async {
    _prefs = await SharedPreferences.getInstance();
    _tutorialFinished = _prefs?.getBool(finishedTutorialKey) ?? false;
    _loadedValues = true;
    notifyListeners();
  }
}
