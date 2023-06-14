import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShowQRCodeView extends StatelessWidget {
  /// The shortcut for which a QR code should be shown.
  final ShortcutRoute shortcut;

  const ShowQRCodeView({Key? key, required this.shortcut}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int totalAddressCharacterCount = 0;
    for (final waypoint in shortcut.waypoints) {
      totalAddressCharacterCount += waypoint.address?.length ?? 0;
    }

    Shortcut shortcutCopy = ShortcutRoute(
      name: shortcut.name,
      waypoints: [],
    );

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
