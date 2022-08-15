import 'package:flutter/material.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/service.dart';
import 'package:provider/provider.dart';

class ShortcutsService with ChangeNotifier {
  /// All available shortcuts.
  List<Shortcut>? shortcuts;

  ShortcutsService();

  /// Reset the shortcuts service.
  Future<void> reset() async {
    shortcuts = null;
  }

  /// Load the custom shortcuts.
  Future<void> loadShortcuts(BuildContext context) async {
    if (shortcuts != null) return;
    final settings = Provider.of<SettingsService>(context, listen: false);
    // TODO: Make shortcuts non-static (configurable by the user).
    shortcuts = settings.backend.shortcuts;
    notifyListeners();
  }
}
