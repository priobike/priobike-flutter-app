import 'package:flutter/material.dart';
import 'package:priobike/gamification/hub/services/profile_service.dart';
import 'package:priobike/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service which manages the gamification intro views.
class GameIntroService with ChangeNotifier {
  /// The key under which the information if the user has started the intro is stored in shared preferences.
  static const finishedIntroKey = "priobike.game.finishedIntro";

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

  /// Variable which is true, when the intro process is currently in a loading state.
  bool _loading = false;

  bool get loading => _loading;

  /// Bool which is true, when the user finished the tutorial.
  bool _introFinished = false;

  bool get introFinished => _introFinished;

  /// Set the tutorial as finished in the shared prefs and also store the selected game prefs there.
  void finishIntro() async {
    _loading = true;
    notifyListeners();
    _prefs?.setString(UserProfileService.userNameKey, username);
    _prefs?.setStringList(UserProfileService.userPreferencesKey, _gamePrefs);
    _prefs?.setBool(finishedIntroKey, true);
    await getIt<UserProfileService>().loadOrCreateProfile();
    _introFinished = true;
    pageChanged = true;
    _loading = false;
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
    loadValues();
  }

  /// Get instance of shared preferences and load values.
  void loadValues() async {
    _prefs = await SharedPreferences.getInstance();
    _introFinished = _prefs?.getBool(finishedIntroKey) ?? false;
    _loadedValues = true;
    notifyListeners();
  }
}
