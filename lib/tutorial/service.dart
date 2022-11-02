import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Tutorial with ChangeNotifier {
  /// Tutorial ids and if they have been completed.
  Map<String, bool>? completed;

  Tutorial({
    this.completed,
  });

  /// Load the completed tutorials from the shared preferences.
  Future<void> loadCompleted() async {
    if (completed != null) return;
    final storage = await SharedPreferences.getInstance();
    final completedStr = storage.getString("priobike.tutorial.completed");
    if (completedStr != null) {
      completed = Map<String, bool>.from(jsonDecode(completedStr));
    } else {
      completed = {};
    }
    notifyListeners();
  }

  /// Store the completed tutorials in the shared preferences.
  Future<void> storeCompleted() async {
    if (completed == null) return;
    final storage = await SharedPreferences.getInstance();
    await storage.setString(
        "priobike.tutorial.completed", jsonEncode(completed));
  }

  /// Delete the completed tutorials from the shared preferences.
  Future<void> deleteCompleted() async {
    final storage = await SharedPreferences.getInstance();
    await storage.remove("priobike.tutorial.completed");
    completed = {};
    notifyListeners();
  }

  /// Check if a tutorial has been completed.
  bool? isCompleted(String id) {
    if (completed == null) return null;
    return completed![id] ?? false;
  }

  /// Mark a tutorial as completed.
  Future<void> complete(String id) async {
    if (completed == null) return;
    completed![id] = true;
    await storeCompleted();
    notifyListeners();
  }
}
