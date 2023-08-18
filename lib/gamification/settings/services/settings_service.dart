import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameSettingsService with ChangeNotifier {
  /// Shared preferences instance to store and retrieve at which point of the intro the user is.
  SharedPreferences? _prefs;
}
