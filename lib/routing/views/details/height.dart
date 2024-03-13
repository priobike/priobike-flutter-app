import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/services/settings.dart';

// Rough value on how many lines per route is okay to display the height chart smoothly.
const maxPointsPerRouteHeightChart = 100;

// Interval in which the maxima and minima will be split of.
const maximaMinimaInterval = 20;

class RouteHeightChart extends StatefulWidget {
  const RouteHeightChart({super.key});

  @override
  RouteHeightChartState createState() => RouteHeightChartState();
}

class HeightData {
  final double height;
  final double distance;

  HeightData(this.height, this.distance);
}

/// An Element of the chart. There is one main line and an arbitrary number of alternatives lines.
class LineElement {
  /// Whether the route is currently selected line by the user.
  final bool isMainLine;

  /// The height data of the route.
  final List<HeightData> series;

  /// The length of the route.
  final double routeLength;

  LineElement(this.isMainLine, this.series, this.routeLength);
}

class RouteHeightPainter extends CustomPainter {
  /// The BuildContext of the chart.
  BuildContext context;

  /// The state of the chart.
  RouteHeightChartState routeHeightChartState;

  /// The padding of the chart.
  final paddingTopBottom = 14.0;
  final paddingLeft = 16.0;
  final paddingRight = 16.0;

  /// The Canvas to draw on.
  late Canvas canvas;

  /// The size of the canvas.
  late Size size;

  /// The starting point of the y-axis. Used to set the height of the x-axis and the associated label.
  late double yStartingPoint;

  /// The upper and lower ends of the y-axis.
  /// The custom painter has the coords (0,0) on the top left corner, so the yTop is actually the smaller value.
  late double yTop, yBottom;

  /// The minimum height of the route -1.0 as padding for the y-axis.
  late double minHeight;

  /// The maximum height of the route +1.0 as padding for the y-axis.
  late double maxHeight;

  RouteHeightPainter(this.context, this.routeHeightChartState);

  /// Sets the basic variables for the painter.
  void initializePainter(Canvas canvas, Size size) {
    this.canvas = canvas;
    this.size = size;

    yTop = paddingTopBottom;
    yBottom = size.height - paddingTopBottom;

    // set 1 as padding for the y-axis
    minHeight = routeHeightChartState.minHeight! - 1.0;
    maxHeight = routeHeightChartState.maxHeight! + 1.0;

    // If maxHeight == minHeight (which can only happen at very short distances), the following calculations fails
    // To display it anyway, we set the scale to 0.5
    if (routeHeightChartState.maxHeight == routeHeightChartState.minHeight) {
      yStartingPoint = yBottom - (yBottom - yTop) * 0.5;
    } else {
      final scale = (routeHeightChartState.heightStartPoint! - minHeight) / (maxHeight - minHeight);
      yStartingPoint = yBottom - (yBottom - yTop) * scale;
    }
  }

  /// Draws the axes of the coordinate system.
  void drawCoordSystem() {
    final paint = Paint()
      ..color = Theme.of(context).colorScheme.outline
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    // Y-axis
    final x = paddingLeft;
    canvas.drawLine(
      Offset(x, yTop),
      Offset(x, yBottom),
      paint,
    );

    // X-axis
    // The height of the x-axis is set by the height of the start point
    canvas.drawLine(
      Offset(paddingLeft, yStartingPoint),
      Offset(size.width - paddingRight, yStartingPoint),
      paint,
    );
  }

  /// Draws labels for the x-axis and y-axis.
  void drawCoordSystemLabels() {
    final TextStyle labelTextStyle = TextStyle(
      color: Theme.of(context).colorScheme.outline,
      fontSize: 12,
    );
    // Distance for labels to the axis
    const distanceFromXAxis = 4.0;
    const distanceFromYAxis = 6.0;

    // The top and bottom labels on the y-axis
    final double labelYTop = maxHeight - routeHeightChartState.heightStartPoint!;
    final double labelYBottom = minHeight - routeHeightChartState.heightStartPoint!;

    // How many decimal places to show on the y-axis
    final int decimalPlacesY;

    // How many decimal places to show on the x-axis
    final int decimalPlacesX;

    // The unit for the x-axis
    final String unit;

    // The length of the route
    final double routeLength;

    // If a very flat route is encountered, show more decimal places on y-axis
    if (labelYTop.toStringAsFixed(0) == "0" || labelYBottom.toStringAsFixed(0) == "0") {
      decimalPlacesY = 1;
    } else {
      decimalPlacesY = 0;
    }

    // If a very short route is encountered, units for distance is meters
    if (routeHeightChartState.maxDistance! < 1) {
      unit = "m";
      routeLength = routeHeightChartState.maxDistance! * 1000;
      decimalPlacesX = 0;
    } else {
      unit = "km";
      routeLength = routeHeightChartState.maxDistance!;
      decimalPlacesX = 1;
    }

    // Left label on x-axis
    final xLeftLabel = TextPainter(
      text: TextSpan(
        text: "0 $unit",
        style: labelTextStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    xLeftLabel.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    xLeftLabel.paint(canvas, Offset(paddingLeft, size.height - paddingTopBottom + distanceFromXAxis));

    // Middle label on x-axis
    final xMidLabel = TextPainter(
      text: TextSpan(
        text: "${(routeLength / 2).toStringAsFixed(decimalPlacesX)} $unit",
        style: labelTextStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    xMidLabel.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    xMidLabel.paint(
        canvas, Offset(size.width / 2 - xMidLabel.width / 2, size.height - paddingTopBottom + distanceFromXAxis));

    // Right label on x-axis
    final xRightLabel = TextPainter(
      text: TextSpan(
        text: "${routeLength.toStringAsFixed(decimalPlacesX)} $unit",
        style: labelTextStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    xRightLabel.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    xRightLabel.paint(canvas,
        Offset(size.width - paddingRight - xRightLabel.width, size.height - paddingTopBottom + distanceFromXAxis));

    // Bottom label on y-axis
    final yMinLabel = TextPainter(
      text: TextSpan(
        text: labelYBottom.toStringAsFixed(decimalPlacesY),
        style: labelTextStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    yMinLabel.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    yMinLabel.paint(
        canvas, Offset(paddingLeft - yMinLabel.width - distanceFromYAxis, size.height - paddingTopBottom - 10));

    // Mid label on y-axis
    // Is only drawn if the mid label is not too close to the top or bottom label
    if (yStartingPoint - 15 > yTop && yStartingPoint + 15 < yBottom) {
      final yMidLabel = TextPainter(
        text: TextSpan(
          text: "0",
          style: labelTextStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      yMidLabel.layout(
        minWidth: 0,
        maxWidth: size.width,
      );
      yMidLabel.paint(
          canvas, Offset(paddingLeft - yMidLabel.width - distanceFromYAxis, yStartingPoint - yMidLabel.height / 2));
    }

    // Top label on y-axis
    final yMaxLabel = TextPainter(
      text: TextSpan(
        text: labelYTop.toStringAsFixed(decimalPlacesY),
        style: labelTextStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    yMaxLabel.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    yMaxLabel.paint(canvas, Offset(paddingLeft - yMaxLabel.width - distanceFromYAxis, paddingTopBottom - 2));
  }

  /// Draws the lines of the chart.
  void drawLines() {
    Paint paintLine;
    Paint paintCircle;
    Paint smoothTransition;

    // Create new list to make sure the main line is always last, so it is drawn on top
    List<LineElement> sortedLineElements = List.empty(growable: true);
    sortedLineElements.addAll(routeHeightChartState.lineElements.where((element) => !element.isMainLine));
    sortedLineElements.add(routeHeightChartState.lineElements.firstWhere((element) => element.isMainLine));

    for (LineElement element in sortedLineElements) {
      if (element.isMainLine) {
        paintLine = Paint()
          ..color = Theme.of(context).colorScheme.primary
          ..strokeWidth = 3
          ..style = PaintingStyle.fill;
        paintCircle = Paint()
          ..color = Theme.of(context).colorScheme.primary
          ..strokeWidth = 3
          ..style = PaintingStyle.fill;
        smoothTransition = Paint()
          ..color = Theme.of(context).colorScheme.primary
          ..strokeWidth = 1
          ..style = PaintingStyle.fill;
      } else {
        paintLine = Paint()
          ..color = Colors.grey
          ..strokeWidth = 2
          ..style = PaintingStyle.fill;
        paintCircle = Paint()
          ..color = Colors.grey
          ..strokeWidth = 2
          ..style = PaintingStyle.fill;
        smoothTransition = Paint()
          ..color = Colors.grey
          ..strokeWidth = 1
          ..style = PaintingStyle.fill;
      }

      const circleSize = 5.0;

      for (HeightData heightData in element.series) {
        // Calculate the coordinates of the current height data
        final height = heightData.height - minHeight;
        final spectrum = maxHeight - minHeight;
        final x = paddingLeft +
            (heightData.distance / routeHeightChartState.maxDistance!) * (size.width - paddingRight - paddingLeft);
        final y =
            size.height - paddingTopBottom - (height / spectrum) * (size.height - paddingTopBottom - paddingTopBottom);

        if (heightData == element.series.last) {
          canvas.drawCircle(Offset(x, y), circleSize, paintCircle);
        } else {
          // Get next height data to draw a line to
          final nextIndex = element.series.indexOf(heightData) + 1;
          final nextHeightData = element.series[nextIndex];
          final nextHeight = nextHeightData.height - minHeight;
          final nextX = paddingLeft +
              (nextHeightData.distance / routeHeightChartState.maxDistance!) *
                  (size.width - paddingRight - paddingLeft);
          final nextY = size.height -
              paddingTopBottom -
              (nextHeight / spectrum) * (size.height - paddingTopBottom - paddingTopBottom);
          canvas.drawLine(Offset(x, y), Offset(nextX, nextY), paintLine);
          // Draw a little circle at the end of the line to make the transition smoother
          canvas.drawCircle(Offset(nextX, nextY), 1, smoothTransition);
        }
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    initializePainter(canvas, size);
    drawCoordSystem();
    drawCoordSystemLabels();
    drawLines();
  }

  @override
  bool shouldRepaint(RouteHeightPainter oldDelegate) => false;
}

class RouteHeightChartState extends State<RouteHeightChart> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated routing service, which is injected by the provider.
  late Settings settings;

  /// The lineElements for the chart.
  List<LineElement> lineElements = List.empty(growable: true);

  /// The maximum distance of a route in km.
  double? maxDistance;

  /// The maximum height of a route in m.
  double? maxHeight;

  /// The maximum height of a route in m.
  double? minHeight;

  /// The start point of the route. Used to orient the chart.
  double? heightStartPoint;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    processRouteData();
  }

  @override
  void initState() {
    super.initState();
    routing = getIt<Routing>();
    routing.addListener(update);
    settings = getIt<Settings>();
    settings.addListener(update);
    processRouteData();
  }

  @override
  void dispose() {
    routing.removeListener(update);
    settings.removeListener(update);
    super.dispose();
  }

  /// Process the route data and create the LineElements for the chart.
  /// Care about max number of line elements to not decrease performance on scroll.
  Future<void> processRouteData() async {
    if (routing.allRoutes == null || routing.allRoutes!.isEmpty) {
      setState(() {});
      return;
    }
    ;
    final List<LineElement> newlineElements = List.empty(growable: true);
    for (var route in routing.allRoutes!) {
      List<GHCoordinate> latlngCoords = route.path.points.coordinates;

      const vincenty = Distance(roundResult: false);
      final data = List<HeightData>.empty(growable: true);
      var prevDist = 0.0;

      // Only pick max number of coords per route.
      // To many lines will make the scrolling laggy.
      // Therefore skip a slight amount of waypoints on big routes.
      // Reduce if to many waypoints.
      double waypointsOverheadFactor = latlngCoords.length / maxPointsPerRouteHeightChart;
      if (waypointsOverheadFactor > 1) {
        // The skip/keep value for the modulo operation.
        // Greater 2 means we can use modulo to skip values.
        // Less then 2 means we can use modulo to keep values.
        // Differentiation due to the limitation of skip and keep for a value less then 2. (natural numbers)
        bool skip;
        int skipKeepValue;

        // Determine maxima and minima points to keep.
        List<int> maximaPointsToKeep = [];
        List<int> minimaPointsToKeep = [];

        // Loop through coords in chunks of maximaMinimaInterval.
        for (int i = 0; i < latlngCoords.length; i = i + maximaMinimaInterval) {
          int? localMaximaIdx;
          int? localMinimaIdx;
          double localMaxima = double.negativeInfinity;
          double localMinima = double.infinity;

          // Loop through chunk.
          for (int j = i; j < i + maximaMinimaInterval; j++) {
            // Catch out of range for last chunk.
            if (j >= latlngCoords.length) continue;

            // Check for local minima.
            if (latlngCoords[j].elevation != null && latlngCoords[j].elevation! < localMinima) {
              localMinima = latlngCoords[j].elevation!;
              localMinimaIdx = j;
            }

            // Check for local maxima.
            if (latlngCoords[j].elevation != null && latlngCoords[j].elevation! > localMaxima) {
              localMaxima = latlngCoords[j].elevation!;
              localMaximaIdx = j;
            }
          }

          // Add local minima and maxima if found.
          if (localMinimaIdx != null) minimaPointsToKeep.add(localMinimaIdx);
          if (localMaximaIdx != null) minimaPointsToKeep.add(localMaximaIdx);
        }

        if (waypointsOverheadFactor > 2) {
          // We need to keep since we want to remove more then half of the points.
          skip = false;
          // Keep every X waypoint.
          // We need to round the waypoints overhead factor.
          // E.g. 400 points => factor = 4 => keep every 4th => 100 waypoints.
          skipKeepValue = waypointsOverheadFactor.toInt();
        } else {
          // We need to skip since we want to remove less then half of the points.
          skip = true;
          // Skip every X = number coords / percentage overhead. (to int)
          // Division by 0 can not occur since factor is always greater then 1 and less then or equal 2.
          // Skip value is at least 2.
          // E.g. 120 points => factor = 1.2 => 120 / ((1.2 - 1) * 100) = 6 => skip every 6th.
          skipKeepValue = latlngCoords.length ~/ ((waypointsOverheadFactor - 1) * 100);
        }

        List<GHCoordinate> reducedWaypointList = [];

        // Separate in skip and keep.
        if (skip) {
          for (var i = 0; i < latlngCoords.length; i++) {
            // Skip coords on skip value except minima/maxima points.
            if (i % skipKeepValue == 0 && !maximaPointsToKeep.contains(i) && !minimaPointsToKeep.contains(i)) continue;
            reducedWaypointList.add(latlngCoords[i]);
          }
        } else {
          for (var i = 0; i < latlngCoords.length; i++) {
            // Keep coords on keep value and minima/maxima points.
            if (i % skipKeepValue != 0 && !maximaPointsToKeep.contains(i) && !minimaPointsToKeep.contains(i)) continue;
            reducedWaypointList.add(latlngCoords[i]);
          }
        }
        latlngCoords = reducedWaypointList;
      }

      for (var i = 0; i < latlngCoords.length; i++) {
        var dist = 0.0;
        final p = latlngCoords[i];
        if (i > 0) {
          final pPrev = latlngCoords[i - 1];
          dist = vincenty.distance(LatLng(pPrev.lat, pPrev.lon), LatLng(p.lat, p.lon));
        }
        prevDist += dist;
        data.add(HeightData(p.elevation ?? 0.0, prevDist / 1000));
      }
      final bool isMainLine = (route.path.points.coordinates == routing.selectedRoute!.path.points.coordinates);

      // The last item of the data stores the total distance of the route
      newlineElements.add(LineElement(isMainLine, data, data.last.distance));

      // save the start point of the main line to orient the chart
      if (isMainLine) {
        heightStartPoint = data.first.height;
      }
    }

    // find min and max values to scale the chart, reset variables first
    double? newMaxDistance;
    double? newMinHeight;
    double? newMaxHeight;
    for (var lineElement in newlineElements) {
      newMaxDistance = newMaxDistance == null ? lineElement.routeLength : max(newMaxDistance, lineElement.routeLength);
      for (HeightData heightData in lineElement.series) {
        newMinHeight = newMinHeight == null ? heightData.height : min(newMinHeight, heightData.height);
        newMaxHeight = newMaxHeight == null ? heightData.height : max(newMaxHeight, heightData.height);
      }
    }

    setState(() {
      lineElements = newlineElements;
      maxDistance = newMaxDistance;
      minHeight = newMinHeight;
      maxHeight = newMaxHeight;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (lineElements.isEmpty || maxDistance == 0.0) return Container();
    if (routing.selectedRoute == null) return Container();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.onTertiary.withOpacity(0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SmallVSpace(),
          Content(
            text: "Höhenprofil",
            context: context,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: 116,
                  child: CustomPaint(
                    painter: RouteHeightPainter(context, this),
                  ),
                ),
              ),
              RotatedBox(
                quarterTurns: -1,
                child: Small(text: "Höhe in Meter", context: context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
