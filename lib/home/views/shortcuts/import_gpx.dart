import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gpx/gpx.dart';
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
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
  late Routing routing;
  List<Wpt> points = [];
  GpxConversion gpxConversionNotifier = GpxConversion();

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
      if (points.isEmpty) {
        ToastMessage.showError('Die GPX Datei konnte nicht geladen werden.');
        if (mounted) Navigator.of(context).pop();
      }
      // check if all waypoints are within Hamburg
      List<Waypoint> initWaypoints = [];
      for (int i = 0; i < points.length; i++) {
        initWaypoints.add(Waypoint(points[i].lat!, points[i].lon!));
      }
      if (!routing.inCityBoundary(initWaypoints)) {
        ToastMessage.showError('Ein oder mehrere Punkte der GPX Datei liegen nicht in Hamburg.');
        if (mounted) Navigator.of(context).pop();
      }
      return points;
    } else {
      if (mounted) Navigator.of(context).pop();
      return [];
    }
  }

  Future<void> convertGpxToWaypoints(List<Wpt> points) async {
    if (points.isEmpty) return;
    List<Waypoint> waypoints = await gpxConversionNotifier.reduceWpts(points, routing);
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
                    SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.width * 0.8,
                        child: WaypointsPictogram(wpts: points, gpxConversionNotifier: gpxConversionNotifier)),
                    const VSpace(),
                    ImportGpxInfo(
                      convertCallback: () async => await convertGpxToWaypoints(points),
                      gpxConversionNotifier: gpxConversionNotifier,
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
