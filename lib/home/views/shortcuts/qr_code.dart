import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

  /// The controller for the camera.
  MobileScannerController? cameraController;

  /// Whether the camera has a flashlight.
  bool hasTorch = false;

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

  /// Callback that is called when the scanner is initialized.
  onScannerInit(MobileScannerController controller, bool hasTorch) {
    this.hasTorch = hasTorch;
    if (cameraController != null) {
      return;
    }
    cameraController = controller;
    setState(() {});
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppBackButton(onPressed: () => Navigator.pop(context)),
                  if (state == QRCodeViewMode.scanning && cameraController != null && hasTorch)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ValueListenableBuilder(
                        valueListenable: cameraController!.torchState,
                        builder: (context, state, child) {
                          switch (state as TorchState) {
                            case TorchState.off:
                              return SmallIconButton(
                                icon: Icons.flashlight_on_rounded,
                                onPressed: () => cameraController!.toggleTorch(),
                              );
                            case TorchState.on:
                              return SmallIconButton(
                                icon: Icons.flashlight_off_rounded,
                                onPressed: () => cameraController!.toggleTorch(),
                              );
                          }
                        },
                      ),
                    ),
                ],
              ),
              const SmallVSpace(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: SubHeader(
                        text: state == QRCodeViewMode.scanning ? "Scanne einen QR Code" : shortcut!.name,
                        context: context,
                      ),
                    ),
                    const SmallVSpace(),
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

                                if (state == QRCodeViewMode.scanning) {
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
                              child: state == QRCodeViewMode.scanning
                                  ? ScanQRCodeView(
                                      onScan: (shortcut) {
                                        setState(
                                          () {
                                            this.shortcut = shortcut;
                                            state = QRCodeViewMode.scanned;
                                          },
                                        );
                                      },
                                      onInit: onScannerInit,
                                    )
                                  : ShowQRCodeView(shortcut: shortcut!),
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
                                BoldContent(
                                  text: "Scanne den QR-Code einer anderen PrioBike-App, um die Route zu erhalten.",
                                  context: context,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          if (state == QRCodeViewMode.showing)
                            Column(
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
                          if (state == QRCodeViewMode.scanned)
                            Column(
                              children: [
                                Content(text: "${shortcut!.waypoints.length} Stationen", context: context),
                                const VSpace(),
                                BigButton(
                                  iconColor: Colors.white,
                                  label: "Speichern!",
                                  onPressed: () => saveShortCut(),
                                  boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
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
