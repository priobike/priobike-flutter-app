import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShowQRCodeView extends StatelessWidget {
  /// The shortcut for which a QR code should be shown.
  final Shortcut shortcut;

  const ShowQRCodeView({Key? key, required this.shortcut}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  AppBackButton(onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SmallVSpace(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: SubHeader(text: shortcut.name, context: context),
              ),
              const SmallVSpace(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Stack(
                  children: [
                    Tile(
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        stops: [
                          0.1,
                          0.9,
                        ],
                        colors: [
                          CI.lightBlue,
                          CI.blue,
                        ],
                      ),
                      showShadow: true,
                      shadowIntensity: 0.6,
                      shadow: Theme.of(context).colorScheme.primary,
                      content: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Tile(
                          fill: Theme.of(context).colorScheme.background,
                          shadowIntensity: 0.05,
                          shadow: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                          content: Column(
                            children: [
                              QrImage(
                                data: shortcut.toJson().toString(),
                                version: QrVersions.auto,
                                padding: const EdgeInsets.all(8),
                                backgroundColor: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const VSpace(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Content(text: "${shortcut.waypoints.length} Stationen", context: context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
