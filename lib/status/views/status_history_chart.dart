import 'package:flutter/material.dart';
import 'package:priobike/main.dart';
import 'package:priobike/status/services/status_history.dart';
import 'package:priobike/status/views/status_tabs.dart';

class StatusHistoryPainter extends CustomPainter {
  /// The BuildContext of the widget.
  BuildContext context;

  /// The time of the chart (day or week).
  final StatusHistoryTime time;

  /// The data points with timestamp and percentage of the route.
  final Map<double, double> percentages;

  /// The padding of the chart.
  final paddingTopBottom = 14.0;
  final paddingLeft = 34.0;
  final paddingRight = 14.0;

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

  StatusHistoryPainter({required this.context, required this.percentages, required this.time});

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
  void drawCoordSystemLabels() {
    final TextStyle labelTextStyle = TextStyle(
      color: Theme.of(context).colorScheme.outline,
      fontSize: 12,
    );
    // Distance for labels to the axis
    const distanceFromXAxis = 4.0;
    const distanceFromYAxis = 6.0;

    final String xLeftLabelString;
    final String xMidLabelString;
    const String xRightLabelString = "Jetzt";

    if (time == StatusHistoryTime.day) {
      final diffToFirstTimeStampSec =
          percentages.entries.toList().last.key.toInt() - percentages.entries.toList().first.key.toInt();
      final diffToFirstTimeStampHour = diffToFirstTimeStampSec / 60 ~/ 60;

      xLeftLabelString = "vor ${diffToFirstTimeStampHour}h";
      xMidLabelString = "vor ${diffToFirstTimeStampHour ~/ 2}h";
    } else {
      final diffToFirstTimeStampSec =
          percentages.entries.toList().last.key.toInt() - percentages.entries.toList().first.key.toInt();
      final diffToFirstTimeStampDay = diffToFirstTimeStampSec / 60 ~/ 60 ~/ 24;
      xLeftLabelString = "vor $diffToFirstTimeStampDay Tagen";
      xMidLabelString = "vor ${diffToFirstTimeStampDay ~/ 2} Tagen";
    }

    // Left label on x-axis
    final xLeftLabel = TextPainter(
      text: TextSpan(
        text: xLeftLabelString,
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
        text: xMidLabelString,
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
        text: xRightLabelString,
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
  }

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
      final height = entry.value;
      final x =
          paddingLeft + (entry.key / nulledPercentages.keys.toList().last) * (size.width - paddingRight - paddingLeft);
      final y =
          size.height - paddingTopBottom - (height / maxHeight) * (size.height - paddingTopBottom - paddingTopBottom);

      if (entry.key == nulledPercentages.entries.last.key) {
        canvas.drawCircle(Offset(x, y), circleSize, paintCircle);
      } else {
        // Get next height data to draw a line to
        final nextIndex = nulledPercentages.keys.toList().indexOf(entry.key) + 1;
        final nextTimestamp = nulledPercentages.keys.toList()[nextIndex];
        final nextPercentage = nulledPercentages.values.toList()[nextIndex];
        final nextHeight = nextPercentage;
        final nextX = paddingLeft +
            (nextTimestamp / nulledPercentages.keys.toList().last) * (size.width - paddingRight - paddingLeft);
        final nextY = size.height -
            paddingTopBottom -
            (nextHeight / maxHeight) * (size.height - paddingTopBottom - paddingTopBottom);
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
    drawCoordSystemLabels();
    drawLines();
  }

  @override
  bool shouldRepaint(StatusHistoryPainter oldDelegate) => false;
}

class StatusHistoryChart extends StatefulWidget {
  /// The time of the chart (day or week).
  final StatusHistoryTime time;

  const StatusHistoryChart({Key? key, required this.time}) : super(key: key);

  @override
  StatusHistoryChartState createState() => StatusHistoryChartState();
}

class StatusHistoryChartState extends State<StatusHistoryChart> {
  late StatusHistory statusHistory;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    statusHistory = getIt<StatusHistory>();
    statusHistory.addListener(update);
  }

  @override
  void dispose() {
    statusHistory.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (statusHistory.hadError || statusHistory.isLoading) return Container();

    if (widget.time == StatusHistoryTime.day && statusHistory.dayPercentages.isEmpty) return Container();
    if (widget.time == StatusHistoryTime.week && statusHistory.weekPercentages.isEmpty) return Container();

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 105,
      child: CustomPaint(
        painter: StatusHistoryPainter(
          context: context,
          percentages:
              widget.time == StatusHistoryTime.day ? statusHistory.dayPercentages : statusHistory.weekPercentages,
          time: widget.time,
        ),
      ),
    );
  }
}
