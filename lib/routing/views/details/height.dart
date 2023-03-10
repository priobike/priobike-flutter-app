import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/services/settings.dart';

class RouteHeightChart extends StatefulWidget {
  const RouteHeightChart({Key? key}) : super(key: key);

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
  /// The route currently selected line by the user.
  final bool isMainLine;

  /// The height data of the line.
  final List<HeightData> series;

  final double minDistance;
  final double maxDistance;

  LineElement(this.isMainLine, this.series, this.minDistance, this.maxDistance);
}

class RouteHeightPainter extends CustomPainter {
  /// The BuildContext of the chart.
  BuildContext context;

  /// The state of the chart.
  RouteHeightChartState routeHeightChart;

  /// The padding of the chart.
  final paddingTopBottom = 14.0;
  final paddingLeft = 16.0;
  final paddingRight = 22.0;

  /// The Canvas to draw on.
  late Canvas canvas;

  /// The starting point of the y-axis. Used to set the height of the x-axis and the associated label.
  late double yStartingPoint;

  /// The size of the canvas.
  late Size size;

  /// The upper and lower ends of the y-axis.
  /// Because of the way the custom painter works, the yTop is actually the smaller value.
  late double yTop, yBottom;

  RouteHeightPainter(this.context, this.routeHeightChart);

  /// Sets the basic variables for the painter.
  void initializePainter(Canvas canvas, Size size) {
    this.canvas = canvas;
    this.size = size;

    yTop = paddingTopBottom;
    yBottom = size.height - paddingTopBottom;

    final scale = (routeHeightChart.hightStartPoint! - routeHeightChart.minHeight!) /
        (routeHeightChart.maxHeight! - routeHeightChart.minHeight!);
    yStartingPoint = yBottom - (yBottom - yTop) * scale;
  }

  /// Draws the axes of the coordinate system.
  void drawCoordSystem() {
    final paint = Paint()
      ..color = Theme.of(context).colorScheme.outline
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;

    // y-axis
    final x = paddingLeft;
    canvas.drawLine(
      Offset(x, yTop),
      Offset(x, yBottom),
      paint,
    );

    // x-axis
    // the height of the x-axis is scaled depending on the height of the start point
    canvas.drawLine(
      Offset(paddingLeft, yStartingPoint),
      Offset(size.width - paddingRight, yStartingPoint),
      paint,
    );
  }

  /// Draws labels for the x-axis and y-axis.
  void drawCoordSystemLabels() {
    TextStyle labelTextStyle = TextStyle(
      color: Theme.of(context).colorScheme.outline,
      fontSize: 10,
    );

    const distanceFromXAxis = 4.0;

    // left label on x-axis
    final xLeftLabel = TextPainter(
      text: TextSpan(
        text: "0.0 km",
        style: labelTextStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    xLeftLabel.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    xLeftLabel.paint(canvas, Offset(paddingLeft, size.height - paddingTopBottom + distanceFromXAxis));

    // middle label on x-axis
    final xMidLabel = TextPainter(
      text: TextSpan(
        text:
            "${routeHeightChart.maxDistance == null ? "0.0" : (routeHeightChart.maxDistance! / 2).toStringAsFixed(1)} km",
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

    // right label on x-axis
    final xRightLabel = TextPainter(
      text: TextSpan(
        text: "${routeHeightChart.maxDistance == null ? "0.0" : routeHeightChart.maxDistance!.toStringAsFixed(1)} km",
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

    const distanceFromYAxis = 4.0;

    // bottom label on y-axis
    final yMinLabel = TextPainter(
      text: TextSpan(
        text: routeHeightChart.minHeight == null
            ? "0"
            : (routeHeightChart.minHeight! - routeHeightChart.hightStartPoint!).toStringAsFixed(0),
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

    // mid label on y-axis
    // only drawn if the mid label is not too close to the top or bottom label
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
      yMidLabel.paint(canvas, Offset(paddingLeft - yMidLabel.width - distanceFromYAxis, yStartingPoint - 5));
    }

    // top label on y-axis
    final yMaxLabel = TextPainter(
      text: TextSpan(
        text: routeHeightChart.maxHeight == null
            ? "0"
            : (routeHeightChart.maxHeight! - routeHeightChart.hightStartPoint!).toStringAsFixed(0),
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

    // create new list to make sure the main line is always last, so it is drawn on top
    List<LineElement> sortedLineElements = List.empty(growable: true);
    sortedLineElements.addAll(routeHeightChart.lineElements.where((element) => !element.isMainLine));
    sortedLineElements.add(routeHeightChart.lineElements.firstWhere((element) => element.isMainLine));

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
        // subtract the min height so that the chart starts at min height instead of 0
        final height = heightData.height - routeHeightChart.minHeight!;
        final maxHeight = routeHeightChart.maxHeight! - routeHeightChart.minHeight!;
        final x = paddingLeft +
            (heightData.distance / routeHeightChart.maxDistance!) * (size.width - paddingRight - paddingLeft);
        final y =
            size.height - paddingTopBottom - (height / maxHeight) * (size.height - paddingTopBottom - paddingTopBottom);

        if (heightData == element.series.last) {
          canvas.drawCircle(Offset(x, y), circleSize, paintCircle);
        } else {
          final nextIndex = element.series.indexOf(heightData) + 1;
          final nextHeightData = element.series[nextIndex];
          final nextHeight = nextHeightData.height - routeHeightChart.minHeight!;
          final nextX = paddingLeft +
              (nextHeightData.distance / routeHeightChart.maxDistance!) * (size.width - paddingRight - paddingLeft);
          final nextY = size.height -
              paddingTopBottom -
              (nextHeight / maxHeight) * (size.height - paddingTopBottom - paddingTopBottom);
          canvas.drawLine(Offset(x, y), Offset(nextX, nextY), paintLine);
          // draw a little circle at the end of the line to make the transition smoother
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

  /// The minimum distance of a route.
  double? minDistance;

  /// The maximum distance of a route.
  double? maxDistance;

  /// The maximum height of a route.
  double? maxHeight;

  /// The maximum height of a route.
  double? minHeight;

  /// The start point of the route. Used to orient the chart.
  double? hightStartPoint;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    processRouteData();
    setState(() {});
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

  /// Process the route data and create the lines for the chart.
  void processRouteData() {
    if (routing.allRoutes == null || routing.allRoutes!.isEmpty) return;
    lineElements = List.empty(growable: true);
    for (var route in routing.allRoutes!) {
      final latlngCoords = route.path.points.coordinates;

      const vincenty = Distance(roundResult: false);
      final data = List<HeightData>.empty(growable: true);
      var prevDist = 0.0;
      for (var i = 0; i < latlngCoords.length - 1; i++) {
        var dist = 0.0;
        final p = latlngCoords[i];
        if (i > 0) {
          final pPrev = latlngCoords[i - 1];
          dist = vincenty.distance(LatLng(pPrev.lat, pPrev.lon), LatLng(p.lat, p.lon));
        }
        prevDist += dist;
        data.add(HeightData(p.elevation ?? 0, prevDist / 1000));
      }
      final bool isMainLine = (latlngCoords == routing.selectedRoute!.path.points.coordinates);

      lineElements.add(
        LineElement(isMainLine, data, data.first.distance, data.last.distance),
      );

      // save the start point of the main line to orient the chart
      if (isMainLine) {
        hightStartPoint = data.first.height;
      }
    }

    // find min and max values to scale the chart
    for (var lineElement in lineElements) {
      minDistance = minDistance == null ? lineElement.minDistance : min(minDistance!, lineElement.minDistance);
      maxDistance = maxDistance == null ? lineElement.maxDistance : max(maxDistance!, lineElement.maxDistance);
      for (HeightData heightData in lineElement.series) {
        minHeight = minHeight == null ? heightData.height : min(minHeight!, heightData.height);
        maxHeight = maxHeight == null ? heightData.height : max(maxHeight!, heightData.height);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (lineElements.isEmpty) return Container();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SmallVSpace(),
          Content(
            text: "Höhenprofil dieser Route",
            context: context,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: 114,
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
