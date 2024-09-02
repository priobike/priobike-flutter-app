import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/v7.dart';

class User {
  /// The current id of the user.
  static String? id;

  /// Get or generate the current user id.
  static Future<String> getOrCreateId() async {
    if (id != null) return id!;
    final prefs = await SharedPreferences.getInstance();
    id = prefs.getString("priobike.userId");
    if (id == null) {
      id = const UuidV7().generate();
      await prefs.setString("priobike.userId", id!);
    }
    return id!;
  }
}
