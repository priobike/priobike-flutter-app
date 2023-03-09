import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
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
  final charts.Series<HeightData, double> series;

  final double minDistance;
  final double maxDistance;

  LineElement(this.isMainLine, this.series, this.minDistance, this.maxDistance);
}

class RouteHeightPainter extends CustomPainter {
  List<LineElement> lineElements = RouteHeightChartState().lineElements;
  BuildContext context;
  RouteHeightChartState routeHeightChart = RouteHeightChartState();

  /// The padding of the chart.
  final paddingLeftRight = 20.0;
  final paddingTopBottom = 14.0;

  /// The Canvas to draw on. Will be initialized in the paint method.
  late Canvas canvas;

  /// The size of the canvas. Will be initialized in the paint method.
  late Size size;

  RouteHeightPainter(this.context);

  /// Draws the coordinate system.
  void drawCoordSystem() {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    // x-axis
    canvas.drawLine(
      Offset(paddingLeftRight, size.height - paddingTopBottom),
      Offset(size.width - paddingLeftRight, size.height - paddingTopBottom),
      paint,
    );
    // y-axis
    canvas.drawLine(
      Offset(paddingLeftRight, paddingTopBottom),
      Offset(paddingLeftRight, size.height - paddingTopBottom),
      paint,
    );
  }

  /// Draws 3 labels for the x-axis and 2 labels for the y-axis.
  void drawCoordSystemLabels() {
    const TextStyle labelTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
    );

    final xLeftLabel = TextPainter(
      text: const TextSpan(
        text: 'Left',
        style: labelTextStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    xLeftLabel.layout(
      minWidth: 0 + paddingLeftRight,
      maxWidth: size.width - paddingLeftRight,
    );
    xLeftLabel.paint(canvas, Offset(0 + paddingLeftRight, size.height - paddingTopBottom + 4));

    final xRightLabel = TextPainter(
      text: const TextSpan(
        text: 'Right',
        style: labelTextStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    xRightLabel.layout(
      minWidth: 0 + paddingLeftRight,
      maxWidth: size.width - paddingLeftRight,
    );
    xRightLabel.paint(
        canvas, Offset(size.width - paddingLeftRight - xRightLabel.width, size.height - paddingTopBottom + 4));

    final xMiddleLabel = TextPainter(
      text: const TextSpan(
        text: 'Middle',
        style: labelTextStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    xMiddleLabel.layout(
      minWidth: 0 + paddingLeftRight,
      maxWidth: size.width - paddingLeftRight,
    );
    xMiddleLabel.paint(canvas, Offset(size.width / 2 - xMiddleLabel.width / 2, size.height - paddingTopBottom + 4));

    const distanceFromYAxis = 4.0;
    final yMinLabel = TextPainter(
      text: const TextSpan(
        text: 'Min',
        style: labelTextStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    yMinLabel.layout(
      minWidth: 0 + paddingLeftRight,
      maxWidth: size.width - paddingLeftRight,
    );
    yMinLabel.paint(
        canvas,
        Offset(
            paddingLeftRight - yMinLabel.width - distanceFromYAxis, size.height - paddingTopBottom - yMinLabel.height));

    final yMaxLabel = TextPainter(
      text: const TextSpan(
        text: 'Max',
        style: labelTextStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    yMaxLabel.layout(
      minWidth: 0 + paddingLeftRight,
      maxWidth: size.width - paddingLeftRight,
    );
    yMaxLabel.paint(canvas, Offset(paddingLeftRight - yMaxLabel.width - distanceFromYAxis, paddingTopBottom - 4));
  }

  @override
  void paint(Canvas canvas, Size size) {
    this.canvas = canvas;
    this.size = size;
    // final chartAxesColor = Theme.of(context).colorScheme.brightness == Brightness.dark
    //     ? charts.MaterialPalette.white
    //     : charts.MaterialPalette.black;

    //routeHeightChart.processRouteData();

    drawCoordSystem();
    drawCoordSystemLabels();
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

  double? minDistance;
  double? maxDistance;

  List<charts.Series<HeightData, double>> seriesList = List.empty(growable: true);

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

      final String id = isMainLine ? 'Height' : 'AlternativeHeight';
      final String colorCode = isMainLine ? '#0073FF' : '#838991';

      lineElements.add(
        LineElement(
            isMainLine,
            charts.Series<HeightData, double>(
              id: id,
              colorFn: (_, __) => charts.Color.fromHex(code: colorCode),
              domainFn: (HeightData data, _) => data.distance,
              measureFn: (HeightData data, _) => data.height,
              data: data,
            ),
            data.first.distance,
            data.last.distance),
      );
    }
    List<charts.Series<HeightData, double>> seriesList = List.empty(growable: true);
    for (var lineElement in lineElements) {
      // find smallest and largest distance
      minDistance = minDistance == null ? lineElement.minDistance : min(minDistance!, lineElement.minDistance);
      maxDistance = maxDistance == null ? lineElement.maxDistance : max(maxDistance!, lineElement.maxDistance);

      if (lineElement.isMainLine) {
        seriesList.add(lineElement.series..setAttribute(charts.rendererIdKey, "mainLine"));
      } else {
        seriesList.add(lineElement.series..setAttribute(charts.rendererIdKey, "alternativeLine"));
      }
    }
  }

  Widget renderLineChart(BuildContext context) {
    final chartAxesColor = Theme.of(context).colorScheme.brightness == Brightness.dark
        ? charts.MaterialPalette.white
        : charts.MaterialPalette.black;

    return charts.LineChart(
      seriesList,
      animate: false,
      customSeriesRenderers: [
        charts.LineRendererConfig(
          customRendererId: "mainLine",
          stacked: true,
          includeArea: true,
          strokeWidthPx: 2,
          roundEndCaps: true,
          areaOpacity: 0.5,
          layoutPaintOrder: 2,
        ),
        charts.LineRendererConfig(
          customRendererId: "alternativeLine",
          stacked: true,
          includeArea: true,
          strokeWidthPx: 2,
          roundEndCaps: true,
          areaOpacity: 0.2,
          layoutPaintOrder: 1,
        )
      ],
      domainAxis: charts.NumericAxisSpec(
        viewport: charts.NumericExtents(
          minDistance ?? 0,
          maxDistance ?? 0,
        ),
        tickProviderSpec: const charts.BasicNumericTickProviderSpec(
          desiredTickCount: 10,
          desiredMinTickCount: 5,
          dataIsInWholeNumbers: false,
        ),
        tickFormatterSpec: charts.BasicNumericTickFormatterSpec(
          (num? value) => (value ?? 0) < 0.01 ? "" : "${value?.toStringAsFixed(1)} km",
        ),
        renderSpec: charts.GridlineRendererSpec(
          labelStyle: charts.TextStyleSpec(
            fontSize: 10,
            color: chartAxesColor,
          ),
          lineStyle: const charts.LineStyleSpec(
            color: charts.MaterialPalette.transparent,
          ),
        ),
      ),
      primaryMeasureAxis: charts.NumericAxisSpec(
        showAxisLine: false,
        tickProviderSpec: const charts.BasicNumericTickProviderSpec(
          zeroBound: true,
          desiredTickCount: 3,
        ),
        renderSpec: charts.GridlineRendererSpec(
          labelStyle: charts.TextStyleSpec(
            fontSize: 10,
            color: chartAxesColor,
          ),
          lineStyle: const charts.LineStyleSpec(
            color: charts.MaterialPalette.transparent,
          ),
        ),
      ),
    );
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
                  height: 128,
                  //width: (MediaQuery.of(context).size.width - 24),
                  //renderLineChart(context),
                  child: CustomPaint(
                    painter: RouteHeightPainter(context),
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
