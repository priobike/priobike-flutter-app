import 'dart:typed_data';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/link_shortener.dart';
import 'package:priobike/main.dart';

class ShowQRCodeView extends StatelessWidget {
  /// The shortcut for which a QR code should be shown.
  final Shortcut shortcut;

  const ShowQRCodeView({super.key, required this.shortcut});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String longLink = getIt<LinkShortener>().getLongLink(shortcut);
    return FutureBuilder<Uint8List?>(
      future: getIt<LinkShortener>().getQr(longLink),
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        if (snapshot.hasError) return Text(snapshot.error.toString());
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        Uint8List qr = snapshot.data!;
        return Padding(
            padding: const EdgeInsets.all(10),
            child: ColorFiltered(
              colorFilter: isDark
                  ? const ColorFilter.matrix(<double>[
                      -1.0, 0.0, 0.0, 0.0, 255.0, //
                      0.0, -1.0, 0.0, 0.0, 255.0, //
                      0.0, 0.0, -1.0, 0.0, 255.0, //
                      0.0, 0.0, 0.0, 1.0, 0.0, //
                    ])
                  : const ColorFilter.matrix(<double>[
                      1.0, 0.0, 0.0, 0.0, 0.0, //
                      0.0, 1.0, 0.0, 0.0, 0.0, //
                      0.0, 0.0, 1.0, 0.0, 0.0, //
                      0.0, 0.0, 0.0, 1.0, 0.0, //
                    ]),
              child: Image.memory(qr),
            ));
      },
    );
  }
}
