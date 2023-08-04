import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Route;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/feedback/views/pictogram.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/tracking/algorithms/converter.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/tracking/views/route_pictrogram.dart';

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

  /// The positions of the track.
  List<Position> positions = [];

  /// The navigation nodes of the driven route.
  List<NavigationNode> routeNodes = [];

  ui.Image? startImage;
  ui.Image? destinationImage;

  /// PageController.
  final PageController pageController = PageController(
    viewportFraction: 0.9,
    initialPage: 0,
  );

  /// TabController.
  TabController? tabController;

  /// Called when a listener callback of a ChangeNotifier is fired.
  Future<void> update() async {
    await loadTrack();
    setState(() {});
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
        if (tracking.previousTracks != null && tracking.previousTracks!.isNotEmpty) {
          routeNodes = getPassedNodes(tracking.previousTracks!.last.routes.values.toList(), vincenty);
        }
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    tracking.removeListener(update);
    settings.removeListener(update);
    pageController.dispose();
    super.dispose();
  }

  /// Display the route on the map.
  Future<void> loadTrack() async {
    if (tracking.previousTracks == null) {
      return;
    }
    if (tracking.previousTracks!.isEmpty) {
      return;
    }

    final track = tracking.previousTracks!.last;

    try {
      final gpsFile = await track.gpsCSVFile;
      final gpsFileLines = await gpsFile.readAsLines();
      positions.clear();
      // Skip the first line, which is the header.
      for (var i = 1; i < gpsFileLines.length; i++) {
        final lineContents = gpsFileLines[i].split(',');
        final time = int.parse(lineContents[0]);
        final lon = double.parse(lineContents[1]);
        final lat = double.parse(lineContents[2]);
        final speed = double.parse(lineContents[3]);
        final accuracy = double.parse(lineContents[4]);
        positions.add(Position(
          timestamp: DateTime.fromMillisecondsSinceEpoch(time),
          latitude: lat,
          longitude: lon,
          speed: speed,
          accuracy: accuracy,
          altitude: 0,
          heading: 0,
          speedAccuracy: 0,
        ));
      }
      // Only create the tab controller if we have route and GPS.
      tabController = TabController(length: 2, vsync: this);
      setState(() {});
    } catch (e) {
      log.w('Could not parse GPS file of last track: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (tracking.previousTracks == null) {
      return Container();
    }
    if (tracking.previousTracks!.isEmpty) {
      return Container();
    }

    final lastTrackDate = DateTime.fromMillisecondsSinceEpoch(tracking.previousTracks!.last.startTime);
    final lastTrackDateFormatted = DateFormat.yMMMMd("de").format(lastTrackDate);
    final lastTrackDuration = tracking.previousTracks!.last.endTime != null
        ? Duration(milliseconds: tracking.previousTracks!.last.endTime! - tracking.previousTracks!.last.startTime)
        : null;
    final lastTrackDurationFormatted = lastTrackDuration != null ? formatDuration(lastTrackDuration) : null;

    final headerTextStyle = TextStyle(
      fontSize: 11,
      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
    );

    final cellTextStyle = TextStyle(
      fontSize: 14,
      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
    );

    final List<Widget> rideDetails = [
      Column(
        children: [
          Text(
            "Datum",
            style: headerTextStyle,
          ),
          Text(
            lastTrackDateFormatted,
            style: cellTextStyle,
          ),
        ],
      ),
      if (lastTrackDurationFormatted != null)
        Column(
          children: [
            Text(
              "Dauer",
              style: headerTextStyle,
            ),
            Text(
              lastTrackDurationFormatted,
              style: cellTextStyle,
            ),
          ],
        ),
      Column(
        children: [
          Text(
            "Distanz",
            style: headerTextStyle,
          ),
          Text(
            "TODO",
            style: cellTextStyle,
          ),
        ],
      ),
      Column(
        children: [
          Text(
            "Durch. Geschw.",
            style: headerTextStyle,
          ),
          Text(
            "TODO",
            style: cellTextStyle,
          ),
        ],
      ),
    ];

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        ClipRect(
          child: ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [0.0, 0.5, 0.9],
                colors: [Colors.transparent, Colors.black, Colors.transparent],
              ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
            },
            blendMode: BlendMode.dstIn,
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.5, 0.9],
                  colors: [Colors.transparent, Colors.black, Colors.transparent],
                ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
              },
              blendMode: BlendMode.dstIn,
              child: Transform.translate(
                offset: const Offset(-100, 100),
                child: Transform.scale(
                  scale: 2.5,
                  child: Image(
                    image: Theme.of(context).colorScheme.brightness == Brightness.dark
                        ? const AssetImage('assets/images/map-dark.png')
                        : const AssetImage('assets/images/map-light.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
        HPad(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SubHeader(
                text: 'Deine letzte Fahrt',
                context: context,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
              const SmallVSpace(),
              if (tabController != null)
                TabPageSelector(
                  controller: tabController!,
                  selectedColor: CI.blue,
                  indicatorSize: 6,
                  borderStyle: BorderStyle.none,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                  key: GlobalKey(),
                ),
              const SmallVSpace(),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 220,
                child: PageView(
                  controller: pageController,
                  clipBehavior: Clip.none,
                  onPageChanged: (int index) {
                    if (tabController != null) {
                      setState(() {
                        tabController!.index = index;
                      });
                    }
                  },
                  children: [
                    if (positions.isNotEmpty)
                      Column(
                        children: [
                          const Text(
                            "GPS-Aufzeichnung",
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.2,
                              color: CI.blue,
                            ),
                          ),
                          SizedBox(
                            height: 200,
                            width: 200,
                            child: TrackPictogram(
                              track: positions,
                              minSpeedColor: CI.blueLight,
                              maxSpeedColor: CI.blue,
                            ),
                          ),
                        ],
                      ),
                    if (routeNodes.isNotEmpty && startImage != null && destinationImage != null)
                      Column(
                        children: [
                          const Text(
                            "Voreingestellte Route",
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.2,
                              color: CI.blue,
                            ),
                          ),
                          SizedBox(
                            height: 200,
                            width: 200,
                            child: RoutePictogram(
                              route: routeNodes,
                              startImage: startImage,
                              destinationImage: destinationImage,
                              lineWidth: 6,
                              iconSize: 20,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const VSpace(),
              GridView.count(
                crossAxisSpacing: 8,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                mainAxisSpacing: 8,
                crossAxisCount: 2,
                childAspectRatio: 4,
                physics: const NeverScrollableScrollPhysics(),
                children: rideDetails,
              ),
              const SmallVSpace(),
            ],
          ),
        )
      ],
    );
  }
}
