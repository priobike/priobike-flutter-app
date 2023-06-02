import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/shimmer.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/logging/logger.dart';

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

  /// The camera state.
  CameraState cameraState = CameraState.initializing;

  /// The controller for the camera.
  CameraController? cameraController;

  /// The shortcut that has been scanned.
  Shortcut? shortcut;

  /// Start the camera and listen to updates of the barcode stream.
  dynamic onControllerCreated(CameraController? newController) async {
    log.i('Camera controller created');
    if (newController == null) {
      cameraState = CameraState.otherError;
      log.e('Camera controller is null');
      return;
    }

    cameraController = newController;

    try {
      await cameraController!.initialize();
      log.i('Camera controller initialized');
      cameraState = CameraState.ready;
    } on CameraException catch (e) {
      if (e.code == "cameraPermission") {
        cameraState = CameraState.permissionNotGranted;
      } else {
        log.e('Failed to initialize camera controller: $e');
        cameraState = CameraState.otherError;
      }
    } catch (e) {
      log.e('Failed to initialize camera controller: $e');
      cameraState = CameraState.otherError;
    }
    setState(() {});
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
        child: ReaderWidget(
            onControllerCreated: onControllerCreated,
            onScanFailure: (e) {
              log.e('Failed to scan QR code: $e');
            },
            onMultiScan: (results) {
              if (shortcut != null) {
                return;
              }
              for (final result in (results as List<Code>)) {
                log.i('Scanned QR code.');
                if (result.text == null) {
                  continue;
                }
                if (result.isValid == false) {
                  continue;
                }
                try {
                  final decodeBase64Json = base64.decode(result.text!);
                  final decodedZipJson = gzip.decode(decodeBase64Json);
                  final originalJson = utf8.decode(decodedZipJson);

                  final shortcut = Shortcut.fromJson(json.decode(originalJson));
                  this.shortcut = shortcut;
                  widget.onScan(shortcut);
                } catch (e) {
                  log.e('Failed to parse QR code into shortcut object: ${result.text}');
                }
              }
            },
            tryInverted: true,
            tryHarder: true,
            resolution: ResolutionPreset.max,
            onScan: (result) async {
              log.i('Scanned QR code.');
              if (shortcut != null) {
                return;
              }
              if (result.text == null) {
                return;
              }
              if (result.isValid == false) {
                return;
              }
              try {
                final decodeBase64Json = base64.decode(result.text!);
                final decodedZipJson = gzip.decode(decodeBase64Json);
                final originalJson = utf8.decode(decodedZipJson);

                final shortcut = Shortcut.fromJson(json.decode(originalJson));
                this.shortcut = shortcut;
                widget.onScan(shortcut);
              } catch (e) {
                log.e('Failed to parse QR code into shortcut object: ${result.text}');
              }
            }),
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
    cameraController?.dispose();
    cameraController = null;
    super.dispose();
  }
}
