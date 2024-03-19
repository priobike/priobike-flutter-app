import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/dialog.dart';
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

  const QRCodeView({super.key, this.shortcut});

  @override
  QRCodeViewState createState() => QRCodeViewState();
}

enum QRCodeViewMode {
  /// The QR code is scanning.
  scanning,

  /// The QR code is showing.
  showing,

  /// The QR code has been scanned.
  scanned,
}

class QRCodeViewState extends State<QRCodeView> {
  Shortcut? shortcut;

  /// The current mode of the view.
  QRCodeViewMode? state;

  @override
  void initState() {
    super.initState();
    shortcut = widget.shortcut;
    if (shortcut == null) {
      state = QRCodeViewMode.scanning;
    } else {
      state = QRCodeViewMode.showing;
    }
  }

  /// Called when a saved shortcut should be scanned.
  saveShortCut() {
    if (shortcut == null) return;
    getIt<shortcuts_service.Shortcuts>().saveNewShortcutObject(shortcut!);
    setState(() {
      state = QRCodeViewMode.showing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWrapper(
      backgroundColor: Theme.of(context).colorScheme.background,
      brightness: Theme.of(context).brightness,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppBackButton(onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: SizedBox(
                        height: 48,
                        child: FittedBox(
                          // Scale the text to fit the width.
                          fit: BoxFit.fitWidth,
                          child: SubHeader(
                            text: state == QRCodeViewMode.scanning
                                ? "Strecke von einem anderem Gerät importieren"
                                : shortcut!.name ?? "",
                            context: context,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const VSpace(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: state == QRCodeViewMode.scanning ? Colors.grey : CI.radkulturRed,
                        borderRadius: BorderRadius.circular(48),
                        boxShadow: state == QRCodeViewMode.scanning
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 4,
                                  blurRadius: 32,
                                  offset: const Offset(0, 20), // changes position of shadow
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: CI.radkulturRed.withOpacity(0.3),
                                  spreadRadius: 4,
                                  blurRadius: 32,
                                  offset: const Offset(0, 24), // changes position of shadow
                                ),
                              ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Tile(
                          fill: Theme.of(context).colorScheme.background,
                          shadowIntensity: 0.05,
                          shadow: Colors.black,
                          borderRadius: BorderRadius.circular(32),
                          padding: const EdgeInsets.all(0),
                          content: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: MediaQuery.of(context).size.width * 0.8,
                            child: state == QRCodeViewMode.scanning
                                ? ScanQRCodeView(
                                    onScan: (shortcut) {
                                      if (!mounted) return;
                                      showSaveShortcutSheet(context, shortcut: shortcut);
                                      setState(
                                        () {
                                          this.shortcut = shortcut;
                                          state = QRCodeViewMode.scanned;
                                        },
                                      );
                                    },
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: ShowQRCodeView(shortcut: shortcut!),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const VSpace(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Column(
                        children: [
                          if (state == QRCodeViewMode.scanning)
                            Column(
                              children: [
                                const VSpace(),
                                Content(
                                  text: "Scanne den QR-Code einer anderen PrioBike-App, um die Route zu erhalten.",
                                  context: context,
                                  textAlign: TextAlign.center,
                                  color: Theme.of(context).colorScheme.tertiary.withOpacity(0.5),
                                ),
                              ],
                            ),
                          if (state == QRCodeViewMode.showing)
                            Column(
                              children: [
                                Content(text: shortcut!.getShortInfo(), context: context, textAlign: TextAlign.center),
                                const VSpace(),
                                BoldSmall(
                                  text: "Scanne diesen QR-Code mit einer anderen PrioBike-App, um die Route zu teilen.",
                                  context: context,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          if (state == QRCodeViewMode.scanned)
                            Column(
                              children: [
                                Content(text: shortcut!.getShortInfo(), context: context),
                                const VSpace(),
                                BigButtonPrimary(
                                  iconColor: Colors.white,
                                  label: "Speichern!",
                                  onPressed: () => saveShortCut(),
                                  boxConstraints:
                                      BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
                                ),
                              ],
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
