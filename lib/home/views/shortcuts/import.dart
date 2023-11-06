import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:gpx/gpx.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/views/shortcuts/gpx_conversion.dart';
import 'package:priobike/home/views/shortcuts/qr_code.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';

import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/routing/services/routing.dart';

class ImportShortcutDialog<E> extends StatefulWidget {
  const ImportShortcutDialog({key}) : super(key: key);

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

  void openQRScanner() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) => const QRCodeView(),
    ));
  }

  Future<void> loadFromGPX() async {
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
    } else {
      return;
    }
    if (points.isEmpty) return;
    List<Waypoint> waypoints = await reduceWpts(points, routing);
    if (mounted) {
      showSaveShortcutSheet(context,
          shortcut: ShortcutRoute(
            id: UniqueKey().toString(),
            name: "Strecke aus GPX",
            waypoints: waypoints,
          ));
    }
    return;
  }

  /// Load text from clipboard and check if it contains a supported route link.
  Future<void> loadFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;

    // Check if the link is from Google Maps, and parse coordinates.
    // Example: https://www.google.de/maps/dir/53.5477601,10.0134786/53.5560959,10.0001031/@53.5572131,9.9904822,14z/data=!4m2!4m1!3e1!5m2!1e4!1e3
    if (data.text!.contains("google") && data.text!.contains("/maps/dir/")) {
      // Parse the coordinates using a regular expression.
      final coordinates = RegExp(r"(\d+\.\d+),(\d+\.\d+)").allMatches(data.text!).map((match) {
        if (match.groupCount != 2) return null;
        return [double.parse(match.group(1)!), double.parse(match.group(2)!)];
      }).toList();
      var waypoints = List<Waypoint>.empty(growable: true);
      for (var i = 0; i < coordinates.length; i++) {
        waypoints.add(Waypoint(coordinates[i]![0], coordinates[i]![1], address: "Wegpunkt ${i + 1}"));
      }
      if (mounted) {
        showSaveShortcutSheet(context,
            shortcut: ShortcutRoute(
              id: UniqueKey().toString(),
              name: "Strecke von Google Maps",
              waypoints: waypoints,
            ));
      }
      return;
    }
    if (data.text!.contains("priobike") && data.text!.contains("/import/")) {
      try {
        String str = data.text!;
        String shortcutBase64 = str.split('/').last;
        final shortcutBytes = base64.decode(shortcutBase64);
        final shortcutUTF8 = utf8.decode(shortcutBytes);
        final Map<String, dynamic> shortcutJson = json.decode(shortcutUTF8);
        shortcutJson['id'] = UniqueKey().toString();
        if (shortcutJson['type'] == "ShortcutLocation") {
          ShortcutLocation shortcut = ShortcutLocation.fromJson(shortcutJson);
          if (mounted) showSaveShortcutSheet(context, shortcut: shortcut);
        } else {
          ShortcutRoute shortcut = ShortcutRoute.fromJson(shortcutJson);
          if (mounted) showSaveShortcutSheet(context, shortcut: shortcut);
        }
      } catch (e) {
        ToastMessage.showError(
            "Keine valider Shortcut: ${data.text!.substring(0, data.text!.length > 20 ? 20 : data.text!.length)}...");
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 2,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 64),
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
                      color: Theme.of(context).colorScheme.onBackground,
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
              onPressed: loadFromGPX,
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
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        const SizedBox(height: 4),
                        Small(
                          text: "Lade eine Route aus einer GPX Datei.",
                          context: context,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48, height: 48, child: Icon(Icons.folder_open_rounded)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Tile(
              fill: Theme.of(context).colorScheme.background,
              onPressed: loadFromClipboard,
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Content(
                          text: "Aus Zwischenablage laden",
                          context: context,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        const SizedBox(height: 4),
                        Small(
                          text: "Kopiere einen Routen-Link aus Google Maps und füge ihn über die Zwischenablage ein.",
                          context: context,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 20,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: BoldSmall(
                            text: "BETA",
                            context: context,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48, height: 48, child: Icon(Icons.content_paste_rounded)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
