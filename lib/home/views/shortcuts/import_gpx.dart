import 'package:flutter/material.dart';
import 'package:gpx/gpx.dart';
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/services/gpx_conversion.dart';
import 'package:priobike/home/views/shortcuts/import_gpx_info.dart';
import 'package:priobike/home/views/shortcuts/gpx_conversion_waypoints_pictogram.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:uuid/v4.dart';

class ImportGpxView extends StatefulWidget {
  final List<Wpt> initPoints;

  const ImportGpxView({super.key, required this.initPoints});

  @override
  ImportGpxViewState createState() => ImportGpxViewState();
}

class ImportGpxViewState extends State<ImportGpxView> {
  late Routing routing;
  List<Wpt> points = [];
  GpxConversion gpxConversionNotifier = GpxConversion();

  @override
  void initState() {
    super.initState();
    routing = getIt<Routing>();
    setState(() => points = widget.initPoints);
  }

  Future<void> convertGpxToWaypoints(List<Wpt> points) async {
    if (points.isEmpty) return;
    List<Waypoint> waypoints = await gpxConversionNotifier.reduceWpts(points, routing);
    getIt<Toast>().showSuccess("Die GPX Strecke wurde erfolgreich konvertiert.");
    if (mounted) {
      showSaveShortcutFromShortcutSheet(
        context,
        shortcut: ShortcutRoute(
          id: const UuidV4().generate(), 
          name: "Strecke aus GPX",
          waypoints: waypoints,
        ),
      );
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWrapper(
      bottomBackgroundColor: Theme.of(context).colorScheme.surface,
      colorMode: Theme.of(context).brightness,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                        child: GpxConversionWaypointsPictogram(
                            wpts: points, gpxConversionNotifier: gpxConversionNotifier)),
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
