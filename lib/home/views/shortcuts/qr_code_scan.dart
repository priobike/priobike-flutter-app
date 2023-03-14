import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/logging/logger.dart';

class ScanQRCodeView extends StatefulWidget {
  /// Called when a QR code has been scanned.
  final void Function(Shortcut shortcut) onScan;

  const ScanQRCodeView({Key? key, required this.onScan}) : super(key: key);

  @override
  ScanQRCodeViewState createState() => ScanQRCodeViewState();
}

class ScanQRCodeViewState extends State<ScanQRCodeView> {
  final log = Logger("QRScanner");

  Barcode? result;
  MobileScannerController cameraController = MobileScannerController();
  Shortcut? shortcut;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: MobileScanner(
        controller: cameraController,
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
              log.i('Shortcut QR code found: ${barcode.rawValue}');
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
    cameraController.dispose();
    super.dispose();
  }
}
