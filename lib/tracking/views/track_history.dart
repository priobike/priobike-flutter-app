import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/tracking/views/track_history_item.dart';

class TrackHistoryView extends StatefulWidget {
  const TrackHistoryView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => TrackHistoryViewState();
}

class TrackHistoryViewState extends State<TrackHistoryView> {
  /// The distance model.
  final vincenty = const Distance(roundResult: false);

  /// The left padding.
  double leftPad = 24;

  /// If the user has scrolled.
  bool hasScrolled = false;

  /// The scroll controller.
  late ScrollController scrollController;

  /// The associated tracking service, which is injected by the provider.
  late Tracking tracking;

  List<Track> newestTracks = [];

  ui.Image? startImage;
  ui.Image? destinationImage;

  /// Called when a listener callback of a ChangeNotifier is fired.
  Future<void> update() async {
    await loadRoutes();
    setState(() {});
  }

  /// Load the routes.
  Future<void> loadRoutes() async {
    if (tracking.previousTracks == null) {
      return;
    }
    if (tracking.previousTracks!.isEmpty) {
      return;
    }

    newestTracks.clear();

    // Get 10 newest tracks
    for (var i = tracking.previousTracks!.length - 1; i >= 0 && i > tracking.previousTracks!.length - 11; i--) {
      newestTracks.add(tracking.previousTracks![i]);
    }
  }

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(
      () {
        if (scrollController.offset > 0) {
          hasScrolled = true;
        }
      },
    );
    tracking = getIt<Tracking>();
    tracking.addListener(update);

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
      },
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    tracking.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double shortcutRightPad = 16;
    final shortcutWidth = (MediaQuery.of(context).size.width / 2) - shortcutRightPad;
    final shortcutHeight = max(shortcutWidth - (shortcutRightPad * 3), 128.0);

    if (startImage == null || destinationImage == null) {
      return Container();
    }

    if (newestTracks.isEmpty) {
      return SizedBox(
        height: 70,
        child: Align(
          alignment: Alignment.center,
          child: Content(
            text: "Keine Fahrten gespeichert.",
            context: context,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
          ),
        ),
      );
    }

    List<Widget> views = [
      AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.only(left: leftPad),
      ),
    ];

    views += newestTracks
            .map(
              (track) => TrackHistoryItemView(
                track: track,
                width: shortcutWidth,
                height: shortcutHeight,
                rightPad: shortcutRightPad,
                vincenty: vincenty,
                startImage: startImage!,
                destinationImage: destinationImage!,
              ),
            )
            .toList() ??
        [];

    if (newestTracks.length < tracking.previousTracks!.length) {
      views.add(
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Content(
              text: "... und ${tracking.previousTracks!.length - newestTracks.length} weitere.",
              context: context,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
            ),
          ),
        ),
      );
    }

    List<Widget> animatedViews = views
        .asMap()
        .entries
        .map(
          (e) => BlendIn(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
            delay: Duration(milliseconds: 250 /* Time until shortcuts are shown */ + 250 * e.key),
            child: e.value,
          ),
        )
        .toList();

    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(children: animatedViews),
    );
  }
}
