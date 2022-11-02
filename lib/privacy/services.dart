import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyPolicy with ChangeNotifier {
  /// The key under which the accepted privacy policy is stored in the user defaults / shared preferences.
  static const key = "priobike.privacy.accepted-policy";

  var hasLoaded = false;

  /// The text of the privacy policy.
  String? text;

  /// An indicator if the privacy policy was confirmed by the user.
  bool? isConfirmed;

  /// An indicator if the privacy policy has changed.
  bool? hasChanged;

  /// Load the privacy policy.
  Future<void> loadPolicy(BuildContext context) async {
    if (hasLoaded) return;
    text = await DefaultAssetBundle.of(context)
        .loadString("assets/text/privacy.txt");
    final storage = await SharedPreferences.getInstance();
    final accepted = storage.getString(key);
    isConfirmed = accepted == text;
    hasChanged = accepted != null && !isConfirmed!;
    hasLoaded = true;

    notifyListeners();
  }

  /// Confirm the privacy policy.
  Future<void> confirm() async {
    if (!hasLoaded) return;
    final storage = await SharedPreferences.getInstance();
    await storage.setString(key, text!);
    isConfirmed = true;

    notifyListeners();
  }
}
