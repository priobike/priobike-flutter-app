import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
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

  /// Show a dialog that asks if the track really shoud be deleted.
  void showDeleteDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        return DialogLayout(
          title: 'Fahrt löschen',
          text: "Bitte bestätige, dass du diese Fahrt löschen möchtest.",
          icon: Icons.delete_rounded,
          iconColor: Theme.of(context).colorScheme.primary,
          actions: [
            BigButton(
              iconColor: Colors.white,
              icon: Icons.delete_forever_rounded,
              fillColor: CI.red,
              label: "Löschen",
              onPressed: () {
                getIt<Tracking>().deleteTrack(widget.track);
                Navigator.of(context).pop();
              },
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            ),
            BigButton(
              label: "Abbrechen",
              onPressed: () => Navigator.of(context).pop(),
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
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
          isScrollControlled: true,
          builder: (context) => TrackDetailsDialog(
              track: widget.track, startImage: widget.startImage, destinationImage: widget.destinationImage),
        ),
        shadow: const Color.fromARGB(255, 0, 0, 0),
        shadowIntensity: 0.08,
        padding: const EdgeInsets.all(4),
        fill: Theme.of(context).colorScheme.background,
        splash: Theme.of(context).colorScheme.primary,
        content: SizedBox(
          height: 148,
          width: 148,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              if (routeNodes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: RoutePictogram(
                    key: UniqueKey(),
                    route: routeNodes,
                    startImage: widget.startImage,
                    destinationImage: widget.destinationImage,
                  ),
                ),
              Positioned(
                top: 13,
                left: 10,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShadowedText(
                      text: "$day.",
                      backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.5),
                      fontSize: widget.width * 0.17,
                      height: 0.9,
                      textColor: CI.blue,
                      fontWeight: FontWeight.bold,
                    ),
                    const SmallHSpace(),
                    SizedBox(
                      width: widget.width * 0.17,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ShadowedText(
                          text: "$monthName\n${year.toString()}",
                          fontSize: 11,
                          height: 1.2,
                          textColor: Theme.of(context).colorScheme.onBackground,
                          backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (trackDurationFormatted != null)
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: ShadowedText(
                    text: trackDurationFormatted,
                    fontSize: 11,
                    height: 1.2,
                    textColor: Theme.of(context).colorScheme.onBackground,
                    backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.5),
                  ),
                ),
              Positioned(
                bottom: 10,
                right: 10,
                child: ShadowedText(
                  text: "Route",
                  backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.5),
                  textColor: CI.blue,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  onPressed: () => showDeleteDialog(context),
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

/// A text with a shadow behind it.
class ShadowedText extends StatelessWidget {
  /// The text to display.
  final String text;

  /// The font size.
  final double fontSize;

  /// The background color.
  final Color backgroundColor;

  /// The stroke width.
  final double strokeWidth = 2.5;

  /// The blur radius of the shadow.
  final double blurRadius = 0.5;

  /// The height of the text.
  final double? height;

  /// The text color.
  final Color? textColor;

  /// The shader.
  final Shader? shader;

  /// Font weight.
  final FontWeight? fontWeight;

  const ShadowedText({
    Key? key,
    required this.text,
    required this.backgroundColor,
    required this.fontSize,
    this.height,
    this.textColor,
    this.shader,
    this.fontWeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            height: height,
            fontWeight: fontWeight,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeWidth = strokeWidth
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius)
              ..shader = shader
              ..color = backgroundColor,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            height: height,
            color: textColor,
            fontWeight: fontWeight,
          ),
        ),
      ],
    );
  }
}
