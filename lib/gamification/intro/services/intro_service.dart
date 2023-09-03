import 'package:flutter/material.dart';
import 'package:priobike/gamification/profile/services/profile_service.dart';
import 'package:priobike/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service which manages the gamification intro views.
class GameIntroService with ChangeNotifier {
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

  /// Bool which is true, when the user has confirmed the game features page.
  bool _confirmedFeaturePage = false;

  bool get confirmedFeaturePage => _confirmedFeaturePage;

  void setConfirmedFeaturePage(bool value) {
    _confirmedFeaturePage = value;
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
    await getIt<GameProfileService>().createProfile(username);
    _introFinished = _prefs?.getBool(GameProfileService.profileExistsKey) ?? false;
    pageChanged = true;
    _loading = false;
    notifyListeners();
  }

  /// Basic constructor which loads the shared preferences and the relevant values.
  GameIntroService() {
    loadValues();
  }

  /// Get instance of shared preferences and load values.
  void loadValues() async {
    _prefs = await SharedPreferences.getInstance();
    _introFinished = _prefs?.getBool(GameProfileService.profileExistsKey) ?? false;
    _loadedValues = true;
    notifyListeners();
  }
}
