import 'package:flutter/material.dart';
import 'package:priobike/logging/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyPolicy with ChangeNotifier {
  /// The key under which the accepted privacy policy is stored in the user defaults / shared preferences.
  static const key = "priobike.privacy.accepted-policy";

  bool hasLoaded = false;

  /// The text of the privacy policy.
  String? assetText;

  /// An indicator if the privacy policy was confirmed by the user.
  bool? isConfirmed;

  /// An indicator if the privacy policy has changed.
  bool? hasChanged;

  /// Load the privacy policy.
  Future<void> loadPolicy(String assetText) async {
    if (hasLoaded) return;

    final storage = await SharedPreferences.getInstance();
    final storedPrivacyPolicy = storage.getString(key);

    // Strings must be have their leading and tailing whitespaces trimmed
    // otherwise Android will have a bug where equals versions of the privacy notice are not equal.
    isConfirmed = storedPrivacyPolicy?.trim() == assetText.trim();
    hasChanged = !isConfirmed!;
    hasLoaded = true;
    notifyListeners();
  }

  /// Delete the stored privacy policy for debugging purposes.
  Future<void> deleteStoredPolicy() async {
    final storage = await SharedPreferences.getInstance();
    bool success = await storage.remove(key);
    (success)
        ? ToastMessage.showSuccess("Datenschutz zurückgesetzt")
        : ToastMessage.showError("Datenschutz konnte nicht zurückgesetzt werden");
    isConfirmed = false;
    hasChanged = true;
    notifyListeners();
  }

  /// Confirm the privacy policy and commits the new version to shared preferences.
  Future<void> confirm(String confirmedPolicy) async {
    if (!hasLoaded) return;
    final storage = await SharedPreferences.getInstance();

    isConfirmed = await storage.setString(key, confirmedPolicy);
    hasChanged = false;
    notifyListeners();
  }
}
