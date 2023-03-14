import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShowQRCodeView extends StatelessWidget {
  /// The shortcut for which a QR code should be shown.
  final Shortcut shortcut;

  const ShowQRCodeView({Key? key, required this.shortcut}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int totalAddressCharacterCount = 0;
    for (final waypoint in shortcut.waypoints) {
      totalAddressCharacterCount += waypoint.address?.length ?? 0;
    }

    Shortcut shortcutCopy = Shortcut(name: shortcut.name, waypoints: []);

    // If the total address character count is too large, we need to trim the addresses
    // such that the total character length is max. 300.
    if (totalAddressCharacterCount > 300) {
      final double factor = 300 / totalAddressCharacterCount;
      for (final waypoint in shortcut.waypoints) {
        String? address = waypoint.address;
        if (address != null) {
          final int newLength = (address.length * factor).round();
          if (factor == 1) {
            address = address.substring(0, newLength);
          } else {
            address = "${address.substring(0, newLength)}..";
          }
        }
        shortcutCopy.waypoints.add(Waypoint(
          waypoint.lat,
          waypoint.lon,
          address: address,
        ));
      }
    } else {
      shortcutCopy = shortcut;
    }

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
    );
  }
}
