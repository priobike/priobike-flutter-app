import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/shimmer.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/logging/logger.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class ScanQRCodeView extends StatefulWidget {
  /// Called when a QR code has been scanned.
  final void Function(Shortcut shortcut) onScan;

  const ScanQRCodeView({Key? key, required this.onScan}) : super(key: key);

  @override
  ScanQRCodeViewState createState() => ScanQRCodeViewState();
}

enum CameraState {
  /// The camera is not initialized yet.
  initializing,

  /// The camera is initialized.
  ready,

  /// The scanner has scanned a QR code.
  permissionNotGranted,

  /// Other error.
  otherError,
}

class ScanQRCodeViewState extends State<ScanQRCodeView> {
  final log = Logger("QRScanner");
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  /// The camera state.
  CameraState cameraState = CameraState.initializing;

  /// The controller for the camera.
  QRViewController? cameraController;

  /// The shortcut that has been scanned.
  Shortcut? shortcut;

  /// The listener for the barcode stream.
  StreamSubscription<Barcode>? listener;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      cameraController?.pauseCamera();
    } else if (Platform.isIOS) {
      cameraController?.resumeCamera();
    }
  }

  /// Start the camera and listen to updates of the barcode stream.
  Future<void> onQRViewCreated(QRViewController controller) async {
    cameraController = controller;
    listener = controller.scannedDataStream.listen((scanData) {
      if (shortcut != null) {
        return;
      }
      if (scanData.code == null) {
        return;
      }
      try {
        final decodeBase64Json = base64.decode(scanData.code!);
        final decodedZipJson = gzip.decode(decodeBase64Json);
        final originalJson = utf8.decode(decodedZipJson);

        final shortcut = Shortcut.fromJson(json.decode(originalJson));
        this.shortcut = shortcut;
        widget.onScan(shortcut);
      } catch (e) {
        log.e('Failed to parse QR code into shortcut object: ${scanData.code!}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (cameraState == CameraState.permissionNotGranted) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_rounded,
            size: 50,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SmallVSpace(),
          Content(
            text: 'Gib der PrioBike App bitte die Kamera-Berechtigung, um QR-Codes zu scannen. '
                'Du kannst die Berechtigung jederzeit in den Einstellungen deines Handys ändern.',
            context: context,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (cameraState == CameraState.otherError) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_rounded,
            size: 50,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SmallVSpace(),
          Content(
            text: 'Es ist ein Fehler aufgetreten. Bitte versuche es noch einmal.',
            context: context,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: QRView(
          key: qrKey,
          onQRViewCreated: onQRViewCreated,
          onPermissionSet: (controller, permission) {
            if (!permission) {
              cameraState = CameraState.permissionNotGranted;
              setState(() {});
              return;
            }
          },
        ),
      ),
      Shimmer(
        linearGradient: const LinearGradient(
          colors: [
            Colors.black,
            Colors.white,
            Colors.black,
          ],
          stops: [0, 0.3, 0.35],
          begin: Alignment(0.0, -1.0),
          end: Alignment(1.0, 2.0),
          tileMode: TileMode.clamp,
        ),
        child: ShimmerLoading(
          isLoading: true,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
      ),
    ]);
  }

  @override
  void dispose() {
    listener?.cancel();
    cameraController?.dispose();
    cameraController = null;
    super.dispose();
  }
}
