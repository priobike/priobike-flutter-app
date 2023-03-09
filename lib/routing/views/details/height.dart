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
  /// The main line determines the min and max distance of the coordiante system and is blue instead of grey.
  final bool isMainLine;

  /// The height data of the line.
  final List<HeightData> series;

  final double minDistance;
  final double maxDistance;

  LineElement(this.isMainLine, this.series, this.minDistance, this.maxDistance);
}

class RouteHeightPainter extends CustomPainter {
  BuildContext context;
  RouteHeightChartState routeHeightChart;

  /// The padding of the chart.
  final paddingTopBottom = 14.0;
  final paddingLeft = 24.0;
  final paddingRight = 24.0;

  /// The Canvas to draw on. Will be initialized in the paint method.
  late Canvas canvas;

  /// The size of the canvas. Will be initialized in the paint method.
  late Size size;

  RouteHeightPainter(this.context, this.routeHeightChart);

  /// Draws the coordinate system.
  void drawCoordSystem() {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;
    // x-axis
    canvas.drawLine(
      Offset(paddingLeft, size.height - paddingTopBottom),
      Offset(size.width - paddingRight, size.height - paddingTopBottom + 1),
      paint,
    );
    // y-axis
    canvas.drawLine(
      Offset(paddingLeft, paddingTopBottom),
      Offset(paddingLeft, size.height - paddingTopBottom + 1),
      paint,
    );
  }

  /// Draws labels for the x-axis and y-axis.
  void drawCoordSystemLabels() {
    const TextStyle labelTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
    );

    const distanceFromXAxis = 4.0;

    // left label on x-axis
    final xLeftLabel = TextPainter(
      text: const TextSpan(
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

    const distanceFromYAxis = 8.0;

    // scale the height so he coordsystem starts at minHeight not at 0
    final maxHeight = routeHeightChart.maxHeight! - routeHeightChart.minHeight!;

    // min label on y-axis
    final yMinLabel = TextPainter(
      text: const TextSpan(
        text: "0",
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

    final yMidLabel = TextPainter(
      text: TextSpan(
        text: routeHeightChart.maxHeight == null ? "0" : (maxHeight / 2).toStringAsFixed(0),
        style: labelTextStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    yMidLabel.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    yMidLabel.paint(
        canvas, Offset(paddingLeft - yMidLabel.width - distanceFromYAxis, size.height / 2 - yMidLabel.height / 2));

    // max label on y-axis
    final yMaxLabel = TextPainter(
      text: TextSpan(
        text: routeHeightChart.maxHeight == null ? "0" : maxHeight.toStringAsFixed(0),
        style: labelTextStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    yMaxLabel.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    yMaxLabel.paint(canvas, Offset(paddingLeft - yMaxLabel.width - distanceFromYAxis, paddingTopBottom - 2));

    // right Label, rotated by 90 degrees
    final rightLabel = TextPainter(
      text: const TextSpan(
        text: 'Höhe in Meter',
        style: labelTextStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    rightLabel.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    canvas.save();
    canvas.translate(paddingLeft - rightLabel.width - distanceFromYAxis, paddingTopBottom);
    canvas.rotate(-pi / 2);
    rightLabel.paint(canvas, Offset(-size.height / 2 - 12, size.width + 32));
    canvas.restore();
  }

  /// Draws the lines of the chart.
  void drawLines() {
    Paint paint;

    for (LineElement element in routeHeightChart.lineElements) {
      if (element.isMainLine) {
        paint = Paint()
          ..color = Colors.blue
          ..strokeWidth = 2
          ..style = PaintingStyle.fill;
      } else {
        paint = Paint()
          ..color = Colors.grey
          ..strokeWidth = 2
          ..style = PaintingStyle.fill;
      }

      for (HeightData heightData in element.series) {
        // subtract the min height so that the chart starts at min height instead of 0
        final height = heightData.height - routeHeightChart.minHeight!;
        final maxHeight = routeHeightChart.maxHeight! - routeHeightChart.minHeight!;
        final x = paddingLeft +
            (heightData.distance / routeHeightChart.maxDistance!) * (size.width - paddingRight - paddingLeft);
        final y =
            size.height - paddingTopBottom - (height / maxHeight) * (size.height - paddingTopBottom - paddingTopBottom);

        const circleSize = 3.0;
        if (heightData == element.series.last) {
          canvas.drawCircle(Offset(x, y), circleSize, paint);
        } else {
          if (heightData == element.series.first) {
            canvas.drawCircle(Offset(x, y), circleSize, paint);
          }
          final nextIndex = element.series.indexOf(heightData) + 1;
          final nextHeightData = element.series[nextIndex];
          final nextHeight = nextHeightData.height - routeHeightChart.minHeight!;
          final nextX = paddingLeft +
              (nextHeightData.distance / routeHeightChart.maxDistance!) * (size.width - paddingRight - paddingLeft);
          final nextY = size.height -
              paddingTopBottom -
              (nextHeight / maxHeight) * (size.height - paddingTopBottom - paddingTopBottom);
          canvas.drawLine(Offset(x, y), Offset(nextX, nextY), paint);
        }
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    this.canvas = canvas;
    this.size = size;
    // final chartAxesColor = Theme.of(context).colorScheme.brightness == Brightness.dark
    //     ? charts.MaterialPalette.white
    //     : charts.MaterialPalette.black;

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
    }
    for (var lineElement in lineElements) {
      // find smallest and largest distance
      minDistance = minDistance == null ? lineElement.minDistance : min(minDistance!, lineElement.minDistance);
      maxDistance = maxDistance == null ? lineElement.maxDistance : max(maxDistance!, lineElement.maxDistance);

      // find largest height
      for (HeightData heightData in lineElement.series) {
        maxHeight = maxHeight == null ? heightData.height : max(maxHeight!, heightData.height);
        minHeight = minHeight == null ? heightData.height : min(minHeight!, heightData.height);
      }
    }
  }

  // Widget renderLineChart(BuildContext context) {
  //   final chartAxesColor = Theme.of(context).colorScheme.brightness == Brightness.dark
  //       ? charts.MaterialPalette.white
  //       : charts.MaterialPalette.black;

  //   return charts.LineChart(
  //     seriesList,
  //     animate: false,
  //     customSeriesRenderers: [
  //       charts.LineRendererConfig(
  //         customRendererId: "mainLine",
  //         stacked: true,
  //         includeArea: true,
  //         strokeWidthPx: 2,
  //         roundEndCaps: true,
  //         areaOpacity: 0.5,
  //         layoutPaintOrder: 2,
  //       ),
  //       charts.LineRendererConfig(
  //         customRendererId: "alternativeLine",
  //         stacked: true,
  //         includeArea: true,
  //         strokeWidthPx: 2,
  //         roundEndCaps: true,
  //         areaOpacity: 0.2,
  //         layoutPaintOrder: 1,
  //       )
  //     ],
  //     domainAxis: charts.NumericAxisSpec(
  //       viewport: charts.NumericExtents(
  //         minDistance ?? 0,
  //         maxDistance ?? 0,
  //       ),
  //       tickProviderSpec: const charts.BasicNumericTickProviderSpec(
  //         desiredTickCount: 10,
  //         desiredMinTickCount: 5,
  //         dataIsInWholeNumbers: false,
  //       ),
  //       tickFormatterSpec: charts.BasicNumericTickFormatterSpec(
  //         (num? value) => (value ?? 0) < 0.01 ? "" : "${value?.toStringAsFixed(1)} km",
  //       ),
  //       renderSpec: charts.GridlineRendererSpec(
  //         labelStyle: charts.TextStyleSpec(
  //           fontSize: 10,
  //           color: chartAxesColor,
  //         ),
  //         lineStyle: const charts.LineStyleSpec(
  //           color: charts.MaterialPalette.transparent,
  //         ),
  //       ),
  //     ),
  //     primaryMeasureAxis: charts.NumericAxisSpec(
  //       showAxisLine: false,
  //       tickProviderSpec: const charts.BasicNumericTickProviderSpec(
  //         zeroBound: true,
  //         desiredTickCount: 3,
  //       ),
  //       renderSpec: charts.GridlineRendererSpec(
  //         labelStyle: charts.TextStyleSpec(
  //           fontSize: 10,
  //           color: chartAxesColor,
  //         ),
  //         lineStyle: const charts.LineStyleSpec(
  //           color: charts.MaterialPalette.transparent,
  //         ),
  //       ),
  //     ),
  //   );
  // }

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
                  height: 96,
                  //width: (MediaQuery.of(context).size.width - 24),
                  //renderLineChart(context),
                  child: CustomPaint(
                    painter: RouteHeightPainter(context, this),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
