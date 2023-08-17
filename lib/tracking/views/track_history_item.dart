import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/tracking/algorithms/converter.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/tracking/views/route_pictrogram.dart';
import 'package:priobike/tracking/views/track_details.dart';

class TrackHistoryItemView extends StatefulWidget {
  /// The track to display.
  final Track track;

  /// The distance model.
  final Distance vincenty;

  /// The width of the view.
  final double width;

  /// The height of the view.
  final double height;

  /// The right padding of the view.
  final double rightPad;

  /// The image of the route start icon.
  final ui.Image startImage;

  /// The image of the route destination icon.
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

  void showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Fahrt löschen"),
          content: const Text("Bitte bestätige, dass du diese Fahrt löschen möchtest."),
          actions: [
            TextButton(
              child: const Text("Abbrechen"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Löschen"),
              onPressed: () {
                getIt<Tracking>().deleteTrack(widget.track);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Parse the date.
    final day = DateTime.fromMillisecondsSinceEpoch(widget.track.startTime).day;
    final monthName = DateFormat.MMMM('de').format(DateTime.fromMillisecondsSinceEpoch(widget.track.startTime));
    final year = DateTime.fromMillisecondsSinceEpoch(widget.track.startTime).year;

    // Determine the duration.
    final secondsDriven =
        widget.track.endTime != null ? (widget.track.endTime! - widget.track.startTime) ~/ 1000 : null;
    final trackDurationFormatted = secondsDriven != null
        ? '${(secondsDriven ~/ 60).toString().padLeft(2, '0')}:${(secondsDriven % 60).toString().padLeft(2, '0')}\nMinuten'
        : null;

    return Container(
      alignment: Alignment.centerLeft,
      width: widget.width,
      padding: EdgeInsets.only(right: widget.rightPad, bottom: 24),
      child: Tile(
        onPressed: () => showAppSheet(
          context: context,
          builder: (context) => TrackDetailsDialog(
              track: widget.track, startImage: widget.startImage, destinationImage: widget.destinationImage),
        ),
        shadow: const Color.fromARGB(255, 0, 0, 0),
        shadowIntensity: 0.08,
        padding: const EdgeInsets.all(4),
        fill: Theme.of(context).colorScheme.background,
        splash: Theme.of(context).colorScheme.primary,
        content: SizedBox(
          height: 160,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
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
              Positioned(
                top: 10,
                left: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$day.",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 0.9,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [
                              CI.blue,
                              CI.blueLight,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(const Rect.fromLTWH(0.0, 0.0, 90.0, 90.0)),
                      ),
                    ),
                    const SmallHSpace(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$monthName\n${year.toString()}",
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trackDurationFormatted != null)
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Text(
                    trackDurationFormatted,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                ),
              const Positioned(
                bottom: 10,
                right: 10,
                child: Text(
                  "Route",
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    color: CI.blue,
                  ),
                ),
              ),
              if (routeNodes.isNotEmpty)
                Positioned(
                  bottom: 10,
                  right: 20,
                  child: SizedBox(
                    height: widget.width * 0.3,
                    width: widget.width * 0.3,
                    child: RoutePictogram(
                      route: routeNodes,
                      startImage: widget.startImage,
                      destinationImage: widget.destinationImage,
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  key: const ValueKey("delete"),
                  onPressed: () => showDeleteDialog(),
                  icon: Icon(
                    Icons.delete_rounded,
                    size: 22,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
