import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Route;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/tracking/views/track_details.dart';

class LastTrackView extends StatefulWidget {
  const LastTrackView({Key? key}) : super(key: key);

  @override
  LastTrackViewState createState() => LastTrackViewState();
}

class LastTrackViewState extends State<LastTrackView> with SingleTickerProviderStateMixin {
  /// The distance model.
  final vincenty = const Distance(roundResult: false);

  /// The associated tracking service, which is injected by the provider.
  late Tracking tracking;

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The newest track.
  Track? track;

  /// The image of the route start icon.
  ui.Image? startImage;

  /// The image of the route destination icon.
  ui.Image? destinationImage;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    getLatestTrack();
    setState(() {});
  }

  /// Gets the latest track.
  void getLatestTrack() {
    track = null;

    if (tracking.previousTracks == null || tracking.previousTracks!.isEmpty) return;

    final backend = getIt<Settings>().backend;
    for (var i = tracking.previousTracks!.length - 1; i >= 0; i--) {
      Track track = tracking.previousTracks![i];
      if (track.backend == backend) {
        setState(() {
          this.track = track;
        });
        break;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    tracking = getIt<Tracking>();
    tracking.addListener(update);
    settings = getIt<Settings>();
    settings.addListener(update);

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        ByteData startBd = await rootBundle.load("assets/images/start.drawio.png");
        final Uint8List startBytes = Uint8List.view(startBd.buffer);
        final ui.Codec startCodec = await ui.instantiateImageCodec(startBytes);
        startImage = (await startCodec.getNextFrame()).image;

        ByteData destinationBd = await rootBundle.load("assets/images/destination.drawio.png");
        final Uint8List destinationBytes = Uint8List.view(destinationBd.buffer);
        final ui.Codec destinationCodec = await ui.instantiateImageCodec(destinationBytes);
        destinationImage = (await destinationCodec.getNextFrame()).image;

        await tracking.loadPreviousTracks();

        getLatestTrack();

        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    tracking.removeListener(update);
    settings.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (track == null || startImage == null || destinationImage == null) return Container();

    return TrackDetailsView(
      key: ValueKey(track!.sessionId),
      track: track!,
      startImage: startImage!,
      destinationImage: destinationImage!,
    );
  }
}
