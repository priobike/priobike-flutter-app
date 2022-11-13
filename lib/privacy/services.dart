import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyPolicy with ChangeNotifier {
  /// The key under which the accepted privacy policy is stored in the user defaults / shared preferences.
  static const key = "priobike.privacy.accepted-policy";

  bool hasLoaded = false;

  /// The text of the privacy policy.
  String storedPrivacyPolicy = '';

  /// An indicator if the privacy policy was confirmed by the user.
  bool isConfirmed = false;

  /// An indicator if the privacy policy has changed.
  bool hasChanged = true;

  /// Load the privacy policy.
  Future<void> loadPolicy(BuildContext context) async {
    if (hasLoaded) return;

    final storage = await SharedPreferences.getInstance();
    final String newPrivacyPolicy = await DefaultAssetBundle.of(context).loadString("assets/text/privacy.txt");
    storedPrivacyPolicy = storage.getString(key) ?? '';

    // Strings must be have their leading and tailing whitespaces trimmed
    // otherwise Android will have a bug where equals versions of the privacy notice are not equal.
    isConfirmed = (newPrivacyPolicy.trim() == storedPrivacyPolicy.trim());

    hasChanged = !isConfirmed;

    hasLoaded = true;

    notifyListeners();
  }

  /// Confirm the privacy policy and commits the new version to shared preferences.
  Future<void> confirm(BuildContext context) async {
    if (!hasLoaded) return;
    final storage = await SharedPreferences.getInstance();
    final String newPrivacyPolicy = await DefaultAssetBundle.of(context).loadString("assets/text/privacy.txt");

    isConfirmed = await storage.setString(key, newPrivacyPolicy);

    notifyListeners();
  }
}
