import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/main.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShowQRCodeView extends StatelessWidget {
  /// The shortcut for which a QR code should be shown.
  final Shortcut shortcut;

  const ShowQRCodeView({super.key, required this.shortcut});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int totalAddressCharacterCount = 0;

    // Check type.
    if (shortcut.runtimeType == ShortcutRoute) {
      for (final waypoint in (shortcut as ShortcutRoute).waypoints) {
        totalAddressCharacterCount += waypoint.address?.length ?? 0;
      }
    } else if (shortcut.runtimeType == ShortcutLocation) {
      totalAddressCharacterCount = (shortcut as ShortcutLocation).waypoint.address?.length ?? 0;
    } else {
      final hint = "Error unknown type ${shortcut.runtimeType} in ShowQRCodeView.";
      log.e(hint);
    }

    Shortcut? shortcutCopy;

    // If the total address character count is too large, we need to trim the addresses
    // such that the total character length is max. 300.
    if (totalAddressCharacterCount > 300) {
      final double factor = 300 / totalAddressCharacterCount;
      shortcutCopy = shortcut.trim(factor);
    } else {
      shortcutCopy = shortcut;
    }

    // Encode the JSON and compress it
    final enCodedJson = utf8.encode(json.encode(shortcutCopy.toJson()));
    final gZipJson = gzip.encode(enCodedJson);
    final base64Json = base64.encode(gZipJson);

    return QrImage(
      data: base64Json,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
      foregroundColor: isDark ? Colors.white : Colors.black,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.circle,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.circle,
      ),
    );
  }
}
