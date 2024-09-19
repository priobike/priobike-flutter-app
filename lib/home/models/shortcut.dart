import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/services/link_shortener.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:uuid/v4.dart';

/// The shortcut represents a saved route or location with a name.
abstract class Shortcut {
  /// The unique id of the shortcut.
  final String id;

  /// The type of the shortcut.
  final String type;

  /// The name of the shortcut.
  String name;

  /// Get the linebreaked name of the shortcut.
  String get linebreakedName;

  /// Checks if the shortcut has invalid waypoints.
  bool isValid();

  /// Trim the addresses of the waypoints, if a factor < 1 is given.
  Shortcut trim(double factor);

  /// Methods which returns a list of waypoints.
  List<Waypoint> getWaypoints();

  /// Returns a String with a short info of the shortcut.
  String getShortInfo();

  /// Returns the icon of the shortcut type.
  Widget getIcon();

  Shortcut({required this.type, required this.name, required this.id});

  Map<String, dynamic> toJson();

  /// Create sharing link of shortcut.
  String getLongLink();

  /// Returns a shortcut from a sharing link.
  static Future<Shortcut?> fromLink(String link) async {
    try {
      // Try to resolve a potential short link.
      String? longLink = await LinkShortener.resolveShortLink(link);

      // If resolving failed, this can have two reasons.
      // 1. The short link was invalid. If this is the case, the subsequent steps will fail, but since we are catching this, this is not a problem.
      // 2. The link is already a short link. This can be the case, if the link got resolved before opening the app.
      // This is usually the case, when the short link is opened in a browser, and due to the resolving of the link in the browser, the app gets openend.
      longLink ??= link;

      // Create a new shortcut from the long link.
      final subUrls = longLink.split('/import/');
      final shortcutBase64 = subUrls.last;
      final shortcutBytes = base64.decode(shortcutBase64);
      final shortcutUTF8 = utf8.decode(shortcutBytes);
      final Map<String, dynamic> shortcutJson = json.decode(shortcutUTF8);
      shortcutJson['id'] = const UuidV4().generate();
      Shortcut shortcut;
      if (shortcutJson['type'] == "ShortcutLocation") {
        shortcut = ShortcutLocation.fromJson(shortcutJson);
      } else {
        shortcut = ShortcutRoute.fromJson(shortcutJson);
      }
      return shortcut;
    } catch (e) {
      return null;
    }
  }
}
