import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyPolicy with ChangeNotifier {
  /// The key under which the accepted privacy policy is stored in the user defaults / shared preferences.
  static const key = "priobike.privacy.accepted-policy";

  /// The bool that holds the state if the privacy policy has loaded.
  bool hasLoaded = false;

  /// The bool that holds the state if there was an error during fetch.
  bool hasError = false;

  /// The text of the privacy policy.
  String? assetText;

  /// An indicator if the privacy policy was confirmed by the user.
  bool? isConfirmed;

  /// An indicator if the privacy policy has changed.
  bool? hasChanged;

  /// Load the privacy policy.
  Future<void> loadPolicy() async {
    // The privacy text from the privacy service.
    String? privacyText;

    try {
      final response =
          await Http.get(Uri.parse("https://${getIt<Settings>().backend.path}/privacy-policy/privacy-policy.md"))
              .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        privacyText = utf8.decode(response.bodyBytes);
      }
    } catch (e, stacktrace) {
      final hint = "Failed to fetch privacy policy: $e $stacktrace";
      log.e(hint);
    }

    // Return has error if assetText is null.
    if (privacyText == null) {
      hasLoaded = true;
      hasError = true;
      notifyListeners();
      return;
    }

    final storage = await SharedPreferences.getInstance();
    assetText = privacyText;
    final storedPrivacyPolicy = storage.getString(key);

    // Strings must be have their leading and tailing whitespaces trimmed
    // otherwise Android will have a bug where equals versions of the privacy notice are not equal.
    isConfirmed = storedPrivacyPolicy?.trim() == assetText?.trim();
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

  /// Resets the loading attributes.
  void resetLoading() {
    hasLoaded = false;
    hasError = false;
    notifyListeners();
  }
}
