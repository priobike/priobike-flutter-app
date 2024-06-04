import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Shortcuts;
import 'package:gpx/gpx.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/views/shortcuts/import_gpx.dart';
import 'package:priobike/home/views/shortcuts/qr_code.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';

class ImportShortcutDialog<E> extends StatefulWidget {
  const ImportShortcutDialog({super.key});

  @override
  ImportShortcutDialogState<E> createState() => ImportShortcutDialogState<E>();
}

class ImportShortcutDialogState<E> extends State<ImportShortcutDialog<E>> {
  late Routing routing;

  @override
  void initState() {
    super.initState();
    routing = getIt<Routing>();
  }

  Future<List<Wpt>> loadGpxFile() async {
    // pick and parse gpx file
    List<Wpt> points = [];
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      String gpxString = file.readAsStringSync();
      Gpx gpx = GpxReader().fromString(gpxString);
      Trk trk = gpx.trks[0];
      Trkseg seg = trk.trksegs[0];
      points = seg.trkpts;
      if (points.isEmpty) {
        ToastMessage.showError('Die GPX Datei konnte nicht geladen werden.');
        return [];
      }
      // check if all waypoints are within Hamburg
      List<Waypoint> initWaypoints = [];
      for (int i = 0; i < points.length; i++) {
        initWaypoints.add(Waypoint(points[i].lat!, points[i].lon!));
      }
      if (!routing.inCityBoundary(initWaypoints)) {
        ToastMessage.showError('Ein oder mehrere Punkte der GPX Datei liegen nicht in Hamburg.');
        return [];
      }
      return points;
    }
    return [];
  }

  Future<void> openQRScanner() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const QRCodeView(),
      ),
    );

    if (result == null) return;

    if (!mounted) return;
    showSaveShortcutFromShortcutSheet(context, shortcut: result);
  }

  void openImportGpxView() async {
    List<Wpt> initPoints = await loadGpxFile();
    if (mounted && initPoints.isNotEmpty) {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (BuildContext context) => ImportGpxView(initPoints: initPoints),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 24, bottom: 8),
            child: BoldContent(text: "Strecke importieren", context: context),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Tile(
              fill: Theme.of(context).colorScheme.surfaceVariant,
              onPressed: openQRScanner,
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    fit: FlexFit.tight,
                    child: Content(
                      text: "PrioBike QR-Code scannen",
                      context: context,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 48, height: 48, child: Icon(Icons.qr_code_scanner_rounded)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Tile(
              fill: Theme.of(context).colorScheme.surfaceVariant,
              onPressed: openImportGpxView,
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Content(
                          text: "Aus GPX Datei laden",
                          context: context,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(height: 4),
                        Small(
                          text: "Lade eine Route aus einer GPX Datei.",
                          context: context,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48, height: 48, child: Icon(Icons.folder_open_rounded)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
