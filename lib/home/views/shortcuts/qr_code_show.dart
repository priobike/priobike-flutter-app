import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/services/link_shortener.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/v4.dart';

class ShowQRCodeView extends StatefulWidget {
  /// The shortcut for which a QR code should be shown.
  final Shortcut shortcut;

  const ShowQRCodeView({super.key, required this.shortcut});

  @override
  ShowQRCodeViewState createState() => ShowQRCodeViewState();
}

class ShowQRCodeViewState extends State<ShowQRCodeView> {
  String? shortLink;

  /// The shortcut without it's name.
  late Shortcut shortcutWithoutName;

  ShowQRCodeViewState();

  @override
  void initState() {
    super.initState();
    _removeNameFromShortcut();
    _encodeShortcut();
  }

  /// Remove the name from the shortcut for privacy reasons.
  void _removeNameFromShortcut() {
    if (widget.shortcut is ShortcutLocation) {
      shortcutWithoutName = ShortcutLocation(
        waypoint: (widget.shortcut as ShortcutLocation).waypoint,
        id: const UuidV4().generate(),
        // Fill with empty name.
        name: "",
      );
    } else if (widget.shortcut is ShortcutRoute) {
      shortcutWithoutName = ShortcutRoute(
        waypoints: (widget.shortcut as ShortcutRoute).waypoints,
        id: const UuidV4().generate(),
        // Fill with empty name.
        name: "",
        routeTimeText: (widget.shortcut as ShortcutRoute).routeTimeText,
        routeLengthText: (widget.shortcut as ShortcutRoute).routeLengthText,
      );
    } else {
      throw Exception("Unknown shortcut type");
    }
  }

  /// Encode the shortcut for the QR code.
  Future<void> _encodeShortcut() async {
    final longLink = shortcutWithoutName.getLongLink();
    final newShortLink = await LinkShortener.createShortLink(longLink);
    if (newShortLink == null) {
      getIt<Toast>().showError("Fehler beim Erstellen des QR Codes");
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() {
      shortLink = newShortLink;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return shortLink == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : QrImageView(
            data: shortLink!,
            version: QrVersions.auto,
            errorCorrectionLevel: QrErrorCorrectLevel.L,
            eyeStyle: QrEyeStyle(
              color: isDark ? Colors.white : Colors.black,
              eyeShape: QrEyeShape.circle,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.circle,
              color: isDark ? Colors.white : Colors.black,
            ),
          );
  }
}
