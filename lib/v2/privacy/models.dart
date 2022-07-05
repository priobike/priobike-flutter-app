import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A privacy policy.
class PrivacyPolicy extends ChangeNotifier {
  /// The text of the privacy policy.
  String text;

  /// An indicator if the privacy policy was confirmed by the user.
  bool isConfirmed;

  /// An indicator if the privacy policy has changed.
  bool hasChanged;

  /// The key under which the accepted privacy policy is stored in the user defaults / shared preferences.
  static const key = "priobike.privacy.accepted-policy";

  /// Load the privacy policy  and check if it was accepted.
  static Future<PrivacyPolicy> load(BuildContext context) async {
    final current = await DefaultAssetBundle.of(context).loadString("assets/text/privacy.txt");
    final storage = await SharedPreferences.getInstance();
    final accepted = storage.getString(key);
    final isConfirmed = accepted == current;
    final hasChanged = accepted != null && !isConfirmed;
    return PrivacyPolicy(text: current, isConfirmed: isConfirmed, hasChanged: hasChanged);
  }

  /// Confirm the privacy policy.
  Future<void> confirm() async {
    final storage = await SharedPreferences.getInstance();
    storage.setString(key, text);
    isConfirmed = true;
    notifyListeners();
  }

  PrivacyPolicy({required this.text, required this.isConfirmed, required this.hasChanged});
}
