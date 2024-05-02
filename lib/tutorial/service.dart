import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:priobike/logging/toast.dart';

class Tutorial with ChangeNotifier {
  /// Tutorial ids and if they have been completed.
  Map<String, bool>? completed;

  /// Tutorial ids and if they are currently active.
  Map<String, bool>? active;

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
    await storage.setString("priobike.tutorial.completed", jsonEncode(completed));
  }

  /// Delete the completed tutorials from the shared preferences.
  Future<void> deleteCompleted() async {
    final storage = await SharedPreferences.getInstance();
    bool success = await storage.remove("priobike.tutorial.completed");
    (success)
        ? ToastMessage.showSuccess("Tutorials zurückgesetzt")
        : ToastMessage.showError("Tutorials konnten nicht zurückgesetzt werden");
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

  /// Load the activated tutorials from the shared preferences.
  Future<void> loadActivated() async {
    if (active != null) return;
    final storage = await SharedPreferences.getInstance();
    final activatedStr = storage.getString("priobike.tutorial.activated");
    if (activatedStr != null) {
      active = Map<String, bool>.from(jsonDecode(activatedStr));
    } else {
      active = {};
    }
    notifyListeners();
  }

  /// Store the activated tutorials in the shared preferences.
  Future<void> storeActivated() async {
    if (active == null) return;
    final storage = await SharedPreferences.getInstance();
    await storage.setString("priobike.tutorial.activated", jsonEncode(active));
  }

  /// Delete the activated tutorials from the shared preferences.
  Future<void> deleteActivated() async {
    final storage = await SharedPreferences.getInstance();
    bool success = await storage.remove("priobike.tutorial.activated");
    (success)
        ? ToastMessage.showSuccess("Tutorials zurückgesetzt")
        : ToastMessage.showError("Tutorials konnten nicht zurückgesetzt werden");
    active = {};
    notifyListeners();
  }

  /// Check if a tutorial has been activated.
  bool? isActive(String id) {
    if (active == null) return null;
    return active![id] ?? false;
  }

  /// Mark a tutorial as active.
  Future<void> activate(String id) async {
    if (active == null) return;
    if (active![id] == true) return;
    active![id] = true;
    await storeCompleted();
    notifyListeners();
  }
}
