import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/tracking/algorithms/converter.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/tracking/views/route_pictrogram.dart';

class TrackHistoryItemView extends StatefulWidget {
  final Track track;

  final Distance vincenty;

  final double width;
  final double height;
  final double rightPad;

  final ui.Image startImage;
  final ui.Image destinationImage;

  const TrackHistoryItemView(
      {Key? key,
      required this.track,
      required this.vincenty,
      required this.width,
      required this.height,
      required this.rightPad,
      required this.startImage,
      required this.destinationImage})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => TrackHistoryItemViewState();
}

class TrackHistoryItemViewState extends State<TrackHistoryItemView> {
  /// The navigation nodes of the driven route.
  List<NavigationNode> routeNodes = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        routeNodes = getPassedNodes(widget.track.routes.values.toList(), widget.vincenty);
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = DateTime.fromMillisecondsSinceEpoch(widget.track.startTime).day;
    final monthName = DateFormat.MMMM('de').format(DateTime.fromMillisecondsSinceEpoch(widget.track.startTime));
    final year = DateTime.fromMillisecondsSinceEpoch(widget.track.startTime).year;

    return Container(
      alignment: Alignment.centerLeft,
      constraints: BoxConstraints(minWidth: widget.width, maxWidth: widget.width),
      padding: EdgeInsets.only(right: widget.rightPad, bottom: 24),
      child: Tile(
        shadow: const Color.fromARGB(255, 0, 0, 0),
        shadowIntensity: 0.08,
        padding: const EdgeInsets.all(4),
        content: Stack(children: [
          Positioned.fill(
            child: Container(
              foregroundDecoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: Theme.of(context).colorScheme.brightness == Brightness.dark
                      ? [
                          Theme.of(context).colorScheme.background,
                          Theme.of(context).colorScheme.background,
                          Theme.of(context).colorScheme.background.withOpacity(0.9),
                          Theme.of(context).colorScheme.background.withOpacity(0.8),
                          Theme.of(context).colorScheme.background.withOpacity(0.7),
                        ]
                      : [
                          Theme.of(context).colorScheme.background,
                          Theme.of(context).colorScheme.background,
                          Theme.of(context).colorScheme.background.withOpacity(0.6),
                          Theme.of(context).colorScheme.background.withOpacity(0.5),
                          Theme.of(context).colorScheme.background.withOpacity(0.3),
                        ],
                ),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Image(
                  image: Theme.of(context).colorScheme.brightness == Brightness.dark
                      ? const AssetImage('assets/images/map-dark.png')
                      : const AssetImage('assets/images/map-light.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: widget.height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$day.",
                        style: TextStyle(
                          fontSize: 32,
                          color: Theme.of(context).colorScheme.onBackground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SmallHSpace(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            monthName,
                            style: const TextStyle(
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            year.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                  Expanded(child: Container()),
                  SizedBox(
                    height: widget.width * 0.4,
                    width: widget.width * 0.4,
                    child: routeNodes.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(6),
                            child: RoutePictogram(
                              route: routeNodes,
                              startImage: widget.startImage,
                              destinationImage: widget.destinationImage,
                            ),
                          )
                        : Container(),
                  ),
                ],
              ),
            ),
          ),
        ]),
        fill: Theme.of(context).colorScheme.background,
        splash: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

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
