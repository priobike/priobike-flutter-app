import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer show log;

class PrivacyPolicy with ChangeNotifier {
  /// The key under which the accepted privacy policy is stored in the user defaults / shared preferences.
  static const key = "priobike.privacy.accepted-policy";

  bool hasLoaded = false;

  /// The text of the privacy policy.
  String? text;

  /// An indicator if the privacy policy was confirmed by the user.
  bool isConfirmed = false;

  /// An indicator if the privacy policy has changed.
  bool? hasChanged;

  /// Load the privacy policy.
  Future<void> loadPolicy(BuildContext context) async {
    if (hasLoaded) return;

    developer.log("Loading privacy policy");
    final storage = await SharedPreferences.getInstance();

    text = await DefaultAssetBundle.of(context).loadString("assets/text/privacy.txt");

    developer.log('#loadpolicy - Contains key: ${storage.containsKey(key)}');

    final accepted = storage.getString(key) ?? '';

    developer.log('#loadpolicy - Accepted length: ' + accepted.trim().length.toString());
    developer.log('#loadpolicy - Text length: ' + text!.trim().length.toString());

    isConfirmed = (accepted.trim() == text!.trim());

    developer.log('#loadpolicy - accepted.allMatches(text!): ${accepted.allMatches(text!).toString()}');

    developer.log('#loadpolicy - Is confirmed: $isConfirmed');

    hasChanged = ((accepted != null) && (!isConfirmed));
    developer.log('#loadpolicy - Has changed: $hasChanged');

    hasLoaded = true;

    notifyListeners();
  }

  /// Confirm the privacy policy.
  Future<void> confirm() async {
    if (!hasLoaded) return;
    final storage = await SharedPreferences.getInstance();

    developer.log('Contains key: ${storage.containsKey(key)}');

    //storage.reload();

    bool successful = await storage.setString(key, text!);

    developer.log('Set string: $successful');
    developer.log('Storage: $storage');
    developer.log('Key: $key');

    isConfirmed = true;

    notifyListeners();
  }
}
