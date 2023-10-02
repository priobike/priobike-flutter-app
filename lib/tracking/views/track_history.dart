import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/tracking/views/all_track_history.dart';
import 'package:priobike/tracking/views/track_history_item.dart';

class TrackHistoryView extends StatefulWidget {
  const TrackHistoryView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => TrackHistoryViewState();
}

class TrackHistoryViewState extends State<TrackHistoryView> {
  /// The associated tracking service, which is injected by the provider.
  late Tracking tracking;

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The list of the newest tracks.
  List<Track> newestTracks = List.empty(growable: true);

  /// The count of total tracks.
  int totalTracks = 0;

  /// The image of the route start icon.
  ui.Image? startImage;

  /// The image of the route destination icon.
  ui.Image? destinationImage;

  /// Called when a listener callback of a ChangeNotifier is fired.
  Future<void> update() async {
    await loadRoutes();
    setState(() {});
  }

  /// Load the routes.
  Future<void> loadRoutes() async {
    if (tracking.previousTracks == null) return;

    newestTracks.clear();
    totalTracks = 0;

    // Get max. 10 newest tracks
    var i = tracking.previousTracks!.length - 1;
    final backend = getIt<Settings>().backend;
    while (i >= 0) {
      if (tracking.previousTracks![i].backend == backend) {
        if (newestTracks.length < 10) {
          newestTracks.add(tracking.previousTracks![i]);
        }
        totalTracks++;
      }
      i--;
    }
  }

  @override
  void initState() {
    super.initState();

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

        await loadRoutes();
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
    if (startImage == null || destinationImage == null) return Container();
    if (newestTracks.isEmpty) return Container();

    const double shortcutRightPad = 12;
    final shortcutWidth = ((MediaQuery.of(context).size.width - 36) / 2) - shortcutRightPad;

    List<Widget> views = [
      AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.only(left: 12),
      ),
    ];

    views += newestTracks
        .map(
          (track) => TrackHistoryItemTileView(
            key: UniqueKey(),
            track: track,
            width: shortcutWidth,
            startImage: startImage!,
            destinationImage: destinationImage!,
          ),
        )
        .toList();

    // Show a hint for the other tracks if there are more than 10.
    if (newestTracks.length < totalTracks) {
      views.add(
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Content(
              text: "... und ${totalTracks - newestTracks.length} weitere.",
              context: context,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
            ),
          ),
        ),
      );
    }

    // Pad a bit more to the right
    views.add(const SizedBox(width: 4));

    List<Widget> animatedViews = views
        .asMap()
        .entries
        .map(
          (e) => Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: BlendIn(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              delay: Duration(milliseconds: 250 /* Time until shortcuts are shown */ + 250 * e.key),
              child: e.value,
            ),
          ),
        )
        .toList();

    return Column(
      children: [
        BlendIn(
          delay: const Duration(milliseconds: 250),
          child: Row(
            children: [
              const SizedBox(width: 42),
              BoldContent(
                text: "Letzte Fahrten",
                context: context,
              ),
              Expanded(child: Container()),
              IconTextButton(
                label: "Alle anzeigen",
                fillColor: Theme.of(context).colorScheme.background,
                splashColor: Colors.white,
                borderColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08),
                textColor: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AllTracksHistoryView())),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
        const VSpace(),
        SingleChildScrollView(
          // Padding is necessary for Shadow in LightMode
          padding: const EdgeInsets.only(bottom: 18),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: animatedViews,
          ),
        ),
        const VSpace(),
      ],
    );
  }
}
