import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gpx/gpx.dart';
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/views/shortcuts/gpx_conversion.dart';
import 'package:priobike/home/views/shortcuts/import_gpx_info.dart';
import 'package:priobike/home/views/shortcuts/waypoints_pictogram.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';

class ImportGpxView extends StatefulWidget {
  const ImportGpxView({Key? key}) : super(key: key);

  @override
  ImportGpxViewState createState() => ImportGpxViewState();
}

class ImportGpxViewState extends State<ImportGpxView> {
  bool startedConvert = false;
  bool converting = false;
  RecWptsModel recWptsNotifier = RecWptsModel();
  ValueNotifier<bool> startedConvertNotifier = ValueNotifier(false);
  ValueNotifier<bool> convertingNotifier = ValueNotifier(false);
  late Routing routing;
  List<Wpt> points = [];

  void initGpx() async {
    List<Wpt> newPoints = await loadGpxFile();
    setState(() => points = newPoints);
  }

  @override
  void initState() {
    super.initState();
    routing = getIt<Routing>();
    initGpx();
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
      return points;
    }
    throw Exception('Die GPX Datei konnte nicht geladen werden.');
  }

  Future<void> convertGpxToWaypoints(List<Wpt> points) async {
    startedConvertNotifier.value = true;
    convertingNotifier.value = true;
    if (points.isEmpty) return;
    List<Waypoint> waypoints =
        await reduceWpts(points, routing, (List<Wpt> newWpts) => {recWptsNotifier.updateWpts(newWpts)});
    convertingNotifier.value = false;
    ToastMessage.showSuccess("Die GPX Strecke wurde erfolgreich konvertiert.");
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWrapper(
      backgroundColor: Theme.of(context).colorScheme.background,
      brightness: Theme.of(context).brightness,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: ListView(
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppBackButton(onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              if (points.isNotEmpty)
                Column(
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
                            text: "Strecke aus einer GPX Datei importieren",
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
                        color: CI.radkulturRed,
                        borderRadius: BorderRadius.circular(48),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 4,
                            blurRadius: 32,
                            offset: const Offset(0, 20), // changes position of shadow
                          )
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
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: WaypointsPictogram(
                                wpts: points,
                                recWptsModel: recWptsNotifier,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const VSpace(),
                    ImportGpxInfo(
                      convertCallback: () async => await convertGpxToWaypoints(points),
                      startedConvertNotifier: startedConvertNotifier,
                      convertingNotifier: convertingNotifier,
                    )
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
