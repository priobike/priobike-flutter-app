import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/logging/logger.dart';

class ScanQRCodeView extends StatefulWidget {
  /// Called when a QR code has been scanned.
  final void Function(Shortcut shortcut) onScan;

  /// Called when the scanner is initialized.
  final void Function(MobileScannerController controller, bool hasTorch)? onInit;

  const ScanQRCodeView({Key? key, required this.onScan, this.onInit}) : super(key: key);

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

  /// The result of the scan.
  Barcode? result;

  /// The camera state.
  CameraState cameraState = CameraState.initializing;

  /// The controller for the camera.
  MobileScannerController? cameraController;

  /// The shortcut that has been scanned.
  Shortcut? shortcut;

  /// The listener for the barcode stream.
  StreamSubscription<BarcodeCapture>? listener;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(autoStart: false);
    SchedulerBinding.instance.addPostFrameCallback(
      (_) {
        start();
      },
    );
  }

  /// Start the camera and listen to updates of the barcode stream.
  Future<void> start() async {
    if (cameraController == null) {
      return;
    }

    try {
      await cameraController!.start();
      listener = cameraController!.barcodes.listen(
        (capture) {
          if (shortcut != null) {
            return;
          }
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue == null) {
              continue;
            }
            if (barcode.format != BarcodeFormat.qrCode) {
              continue;
            }
            try {
              final decodeBase64Json = base64.decode(barcode.rawValue!);
              final decodedZipJson = gzip.decode(decodeBase64Json);
              final originalJson = utf8.decode(decodedZipJson);

              final shortcut = Shortcut.fromJson(json.decode(originalJson));
              this.shortcut = shortcut;
              widget.onScan(shortcut);
              break;
            } catch (e) {
              log.e('Failed to parse QR code into shortcut object: ${barcode.rawValue}');
            }
          }
        },
      );

      cameraState = CameraState.ready;
    } on MobileScannerException catch (e) {
      if (e.errorCode == MobileScannerErrorCode.permissionDenied) {
        cameraState = CameraState.permissionNotGranted;
      } else if (e.errorCode == MobileScannerErrorCode.genericError) {
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
    if (cameraState == CameraState.initializing) {
      return Container();
    }

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: MobileScanner(
        controller: cameraController,
        onScannerStarted: (MobileScannerArguments? args) {
          if (cameraController == null) {
            return;
          }
          widget.onInit?.call(cameraController!, args?.hasTorch ?? false);
        },
        onDetect: (capture) {
          if (shortcut != null) {
            return;
          }
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue == null) {
              continue;
            }
            if (barcode.format != BarcodeFormat.qrCode) {
              continue;
            }
            try {
              final decodeBase64Json = base64.decode(barcode.rawValue!);
              final decodedZipJson = gzip.decode(decodeBase64Json);
              final originalJson = utf8.decode(decodedZipJson);

              final shortcut = Shortcut.fromJson(json.decode(originalJson));
              this.shortcut = shortcut;
              widget.onScan(shortcut);
              break;
            } catch (e) {
              log.e('Failed to parse QR code into shortcut object: ${barcode.rawValue}');
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    cameraController?.dispose();
    listener?.cancel();
    cameraController = null;
    super.dispose();
  }
}
