import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/shortcuts.dart' as shortcuts_service;
import 'package:priobike/home/views/shortcuts/qr_code_scan.dart';
import 'package:priobike/home/views/shortcuts/qr_code_show.dart';
import 'package:priobike/main.dart';

class QRCodeView extends StatefulWidget {
  /// The shortcut for which a QR code should be shown.
  final Shortcut? shortcut;

  const QRCodeView({Key? key, this.shortcut}) : super(key: key);

  @override
  QRCodeViewState createState() => QRCodeViewState();
}

class QRCodeViewState extends State<QRCodeView> {
  Shortcut? shortcut;

  @override
  void initState() {
    super.initState();
    shortcut = widget.shortcut;
  }

  @override
  Widget build(BuildContext context) {
    final bool scanQRMode = shortcut == null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              AppBackButton(onPressed: () => Navigator.pop(context)),
              const SmallVSpace(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: SubHeader(
                        text: scanQRMode ? "Scan QR Code" : shortcut!.name,
                        context: context,
                      ),
                    ),
                    const SmallVSpace(),
                    Stack(
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
                          shadowIntensity: 0.3,
                          shadow: Theme.of(context).colorScheme.primary,
                          content: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Tile(
                              fill: Theme.of(context).colorScheme.background,
                              shadowIntensity: 0.05,
                              shadow: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                              content: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.65,
                                  height: MediaQuery.of(context).size.width * 0.65,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 750),
                                    switchInCurve: Curves.easeInCubic,
                                    switchOutCurve: Curves.easeOutCubic,
                                    transitionBuilder: (Widget child, Animation<double> animation) {
                                      final inAnimation =
                                          Tween<Offset>(begin: const Offset(0.0, 1.0), end: const Offset(0.0, 0.0))
                                              .animate(animation);
                                      final outAnimation =
                                          Tween<Offset>(begin: const Offset(0.0, 1.0), end: const Offset(0.0, 0.0))
                                              .animate(animation);

                                      if (scanQRMode) {
                                        return ClipRect(
                                          child: SlideTransition(
                                            position: inAnimation,
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: child,
                                            ),
                                          ),
                                        );
                                      } else {
                                        return ClipRect(
                                          child: SlideTransition(
                                            position: outAnimation,
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: child,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: scanQRMode
                                        ? ScanQRCodeView(
                                            onScan: (shortcut) {
                                              setState(
                                                () {
                                                  this.shortcut = shortcut;
                                                  getIt<shortcuts_service.Shortcuts>().saveNewShortcutObject(shortcut);
                                                },
                                              );
                                            },
                                          )
                                        : ShowQRCodeView(shortcut: shortcut!),
                                  )),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const VSpace(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: scanQRMode
                          ? Column(
                              children: [
                                const VSpace(),
                                BoldContent(
                                  text: "Scanne den QR-Code einer anderen PrioBike-App, um die Route zu erhalten.",
                                  context: context,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Content(text: "${shortcut!.waypoints.length} Stationen", context: context),
                                const VSpace(),
                                BoldSmall(
                                  text: "Scanne diesen QR-Code mit einer anderen PrioBike-App, um die Route zu teilen.",
                                  context: context,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
