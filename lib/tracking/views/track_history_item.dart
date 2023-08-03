import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/tracking/algorithms/converter.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/tracking/views/route_pictrogram.dart';

class TrackHistoryItemView extends StatefulWidget {
  final Track track;

  final Distance vincenty;

  final double width;
  final double height;
  final double rightPad;

  final ui.Image? startImage;
  final ui.Image? destinationImage;

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

  var expanded = false;

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

  void toggleExpanded() {
    setState(() {
      expanded = !expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final day = DateTime.fromMillisecondsSinceEpoch(widget.track.startTime).day;
    final monthName = DateFormat.MMMM('de').format(DateTime.fromMillisecondsSinceEpoch(widget.track.startTime));
    final year = DateTime.fromMillisecondsSinceEpoch(widget.track.startTime).year;

    final secondsDriven =
        widget.track.endTime != null ? (widget.track.endTime! - widget.track.startTime) ~/ 1000 : null;

    final trackDurationFormatted = secondsDriven != null
        ? '${(secondsDriven ~/ 60).toString().padLeft(2, '0')}:${(secondsDriven % 60).toString().padLeft(2, '0')}\nMinuten'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
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
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
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
                              const SizedBox(
                                height: 9,
                              ),
                              Text(
                                "$monthName\n${year.toString()}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => toggleExpanded(),
                            icon: Icon(
                              Icons.more_vert_rounded,
                              size: 22,
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      Expanded(child: Container()),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          trackDurationFormatted != null
                              ? Text(
                                  trackDurationFormatted,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.2,
                                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                                  ),
                                )
                              : Container(),
                          routeNodes.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: SizedBox(
                                    height: widget.width * 0.3,
                                    width: widget.width * 0.3,
                                    child: RoutePictogram(
                                      route: routeNodes,
                                      startImage: widget.startImage,
                                      destinationImage: widget.destinationImage,
                                    ),
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ]),
            fill: Theme.of(context).colorScheme.background,
            splash: Theme.of(context).colorScheme.primary,
          ),
        ),
        AnimatedCrossFade(
          firstCurve: Curves.easeInOutCubic,
          secondCurve: Curves.easeInOutCubic,
          sizeCurve: Curves.easeInOutCubic,
          duration: const Duration(milliseconds: 1000),
          firstChild: Container(),
          secondChild: IconTextButton(
            iconColor: Colors.white,
            icon: Icons.delete_rounded,
            label: "Löschen",
            boxConstraints: const BoxConstraints(minWidth: 170),
            onPressed: () {},
          ),
          crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        ),
      ],
    );
  }
}
