import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpx/gpx.dart';
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/home/views/shortcuts/waypoints_pictogram.dart';

class ImportGpxView extends StatefulWidget {
  const ImportGpxView({Key? key}) : super(key: key);

  @override
  ImportGpxViewState createState() => ImportGpxViewState();
}

class ImportGpxViewState extends State<ImportGpxView> {
  @override
  void initState() {
    super.initState();
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
    throw Exception('Couldn\'t load gpx file');
  }

  @override
  Widget build(BuildContext context) {
    List<Position> track = [];
    return AnnotatedRegionWrapper(
        backgroundColor: Theme.of(context).colorScheme.background,
        brightness: Theme.of(context).brightness,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          body: SafeArea(
            child: FutureBuilder<List<Wpt>>(
              future: loadGpxFile(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text(snapshot.error.toString());
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                List<Wpt> points = snapshot.data!;
                return WaypointsPictogram(wpts: points);
              }
            )
          )
        )
    );
  }
}
