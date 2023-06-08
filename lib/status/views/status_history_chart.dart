import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/status/services/status_history.dart';
import 'package:priobike/status/views/status_tabs.dart';

class StatusHistoryPainter extends CustomPainter {
  BuildContext context;

  final Map<double, double> percentages;

  /// The padding of the chart.
  final paddingTopBottom = 14.0;
  final paddingLeft = 16.0;
  final paddingRight = 16.0;

  /// The Canvas to draw on.
  late Canvas canvas;

  /// The size of the canvas.
  late Size size;

  /// The upper and lower ends of the y-axis.
  /// The custom painter has the coords (0,0) on the top left corner, so the yTop is actually the smaller value.
  late double yTop, yBottom;

  /// The minimum height of the route -1.0 as padding for the y-axis.
  late double minHeight = 0;

  /// The maximum height of the route +1.0 as padding for the y-axis.
  late double maxHeight = 1;

  StatusHistoryPainter({required this.context, required this.percentages});

  /// Sets the basic variables for the painter.
  void initializePainter(Canvas canvas, Size size) {
    this.canvas = canvas;
    this.size = size;

    yTop = paddingTopBottom;
    yBottom = size.height - paddingTopBottom;
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
    canvas.drawLine(
      Offset(paddingLeft, yBottom),
      Offset(size.width - paddingRight, yBottom),
      paint,
    );
  }

  /// Draws labels for the x-axis and y-axis.
  /* void drawCoordSystemLabels() {
    final TextStyle labelTextStyle = TextStyle(
      color: Theme.of(context).colorScheme.outline,
      fontSize: 12,
    );
    // Distance for labels to the axis
    const distanceFromXAxis = 4.0;
    const distanceFromYAxis = 6.0;

    // The top and bottom labels on the y-axis
    final double labelYTop = maxHeight;
    final double labelYBottom = minHeight;

    // How many decimal places to show on the y-axis
    final int decimalPlacesY;

    // How many decimal places to show on the x-axis
    final int decimalPlacesX;

    // The unit for the x-axis
    final String unit;

    // The length of the route
    final double routeLength;

    // Left label on x-axis
    final xLeftLabel = TextPainter(
      text: TextSpan(
        text: "10:00", //TODO: Add timestamp
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
        text: "11:00", //TODO: Add timestamp
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
        text: "12:00", //TODO: Add timestamp
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
        text: "0%",
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
          text: "50%",
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
        text: "100%",
        style: labelTextStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    yMaxLabel.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    yMaxLabel.paint(canvas, Offset(paddingLeft - yMaxLabel.width - distanceFromYAxis, paddingTopBottom - 2));
  }*/

  /// Draws the lines of the chart.
  void drawLines() {
    Paint paintLine = Paint()
      ..color = Theme.of(context).colorScheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.fill;
    Paint paintCircle = Paint()
      ..color = Theme.of(context).colorScheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.fill;
    Paint smoothTransition = Paint()
      ..color = Theme.of(context).colorScheme.primary
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;

    const circleSize = 5.0;

    Map<double, double> nulledPercentages = {};

    for (final entry in percentages.entries) {
      nulledPercentages[entry.key - percentages.entries.toList()[0].key] = entry.value;
    }

    for (final entry in nulledPercentages.entries) {
      // Calculate the coordinates of the current height data
      final height = entry.value - minHeight;
      final spectrum = maxHeight - minHeight;
      final x =
          paddingLeft + (entry.key / nulledPercentages.keys.toList().last) * (size.width - paddingRight - paddingLeft);
      final y =
          size.height - paddingTopBottom - (height / spectrum) * (size.height - paddingTopBottom - paddingTopBottom);

      if (entry.key == nulledPercentages.entries.last.key) {
        canvas.drawCircle(Offset(x, y), circleSize, paintCircle);
      } else {
        // Get next height data to draw a line to
        final nextIndex = nulledPercentages.keys.toList().indexOf(entry.key) + 1;
        final nextTimestamp = nulledPercentages.keys.toList()[nextIndex];
        final nextPercentage = nulledPercentages.values.toList()[nextIndex];
        final nextHeight = nextPercentage - minHeight;
        final nextX = paddingLeft +
            (nextTimestamp / nulledPercentages.keys.toList().last) * (size.width - paddingRight - paddingLeft);
        final nextY = size.height -
            paddingTopBottom -
            (nextHeight / spectrum) * (size.height - paddingTopBottom - paddingTopBottom);
        print(Offset(x, y));
        print(Offset(nextX, nextY));
        canvas.drawLine(Offset(x, y), Offset(nextX, nextY), paintLine);
        // Draw a little circle at the end of the line to make the transition smoother
        canvas.drawCircle(Offset(nextX, nextY), 1, smoothTransition);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    initializePainter(canvas, size);
    drawCoordSystem();
    // drawCoordSystemLabels();
    drawLines();
  }

  @override
  bool shouldRepaint(StatusHistoryPainter oldDelegate) => false;
}

class StatusHistoryChart extends StatefulWidget {
  final StatusHistoryTime time;

  const StatusHistoryChart({Key? key, required this.time}) : super(key: key);

  @override
  StatusHistoryChartState createState() => StatusHistoryChartState();
}

class StatusHistoryChartState extends State<StatusHistoryChart> {
  late StatusHistory statusHistory;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
/*
    processHistoryData();
*/
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    statusHistory = getIt<StatusHistory>();
    statusHistory.addListener(update);
/*
    processHistoryData();
*/
  }

  @override
  void dispose() {
    statusHistory.removeListener(update);
    super.dispose();
  }

  /*/// Process the history data and create the LineElements for the chart.
  void processHistoryData() {
    if (statusHistory.isLoading) return;
    if (statusHistory.hadError) return;

    for (final )




    for (var route in routing.allRoutes!) {
      final latlngCoords = route.path.points.coordinates;

      const vincenty = Distance(roundResult: false);
      final data = List<HistoryData>.empty(growable: true);
      var prevDist = 0.0;
      for (var i = 0; i < latlngCoords.length; i++) {
        var dist = 0.0;
        final p = latlngCoords[i];
        if (i > 0) {
          final pPrev = latlngCoords[i - 1];
          dist = vincenty.distance(LatLng(pPrev.lat, pPrev.lon), LatLng(p.lat, p.lon));
        }
        prevDist += dist;
        data.add(HistoryData(p.elevation ?? 0.0, prevDist / 1000));
      }
      final bool isMainLine = (latlngCoords == routing.selectedRoute!.path.points.coordinates);

      // The last item of the data stores the total distance of the route
      series.add(data);

      // save the start point of the main line to orient the chart
      if (isMainLine) {
        heightStartPoint = data.first.height;
      }
    }*/

  @override
  Widget build(BuildContext context) {
    if (statusHistory.hadError || statusHistory.isLoading) return Container();

    if (widget.time == StatusHistoryTime.day && statusHistory.dayPercentages.isEmpty) return Container();
    if (widget.time == StatusHistoryTime.week && statusHistory.weekPercentages.isEmpty) return Container();

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        RotatedBox(
          quarterTurns: -1,
          child: Small(text: "Datenqualität", context: context),
        ),
        Expanded(
          child: SizedBox(
            height: 105,
            child: CustomPaint(
              painter: StatusHistoryPainter(
                context: context,
                percentages:
                    widget.time == StatusHistoryTime.day ? statusHistory.dayPercentages : statusHistory.weekPercentages,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
