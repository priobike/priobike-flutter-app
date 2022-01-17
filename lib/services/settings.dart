import 'package:flutter/material.dart';
import 'package:priobike/utils/logger.dart';

class SettingsService with ChangeNotifier {
  Logger log = Logger("SettingsService");

  ThemeMode currentThemeMode = ThemeMode.dark;

  SettingsService() {
    log.i('SettingsService started');
  }

  ThemeMode getThemeMode() {
    return currentThemeMode;
  }

  void setThemeMode(ThemeMode themeMode) {
    currentThemeMode = themeMode;
    notifyListeners();
  }
}
