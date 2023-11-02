import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/status/services/status_history.dart';
import 'package:priobike/status/views/status_tabs.dart';

class StatusHistoryPainter extends CustomPainter {
  /// The BuildContext of the widget.
  final BuildContext context;

  /// Which time period to display.
  final StatusHistoryTime time;

  /// The data points with timestamp and percentage of the route.
  final Map<double, double> percentages;

  /// If the card should be highlighted as a problematic.
  final bool isProblem;

  /// The top and bottom padding of the chart.
  final paddingTopBottom = 10.0;

  /// The left padding of the chart.
  final paddingLeft = 35.0;

  /// The right padding of the chart.
  final paddingRight = 10.0;

  /// The Canvas to draw on.
  late Canvas canvas;

  /// The size of the canvas.
  late Size size;

  /// The upper and lower ends of the y-axis.
  /// The custom painter has the coords (0,0) on the top left corner, so the yTop is actually the smaller value.
  late double yTop, yBottom;

  /// If the darkmode is activated.
  late bool isDark;

  StatusHistoryPainter({required this.context, required this.percentages, required this.time, required this.isProblem});

  /// Sets the basic variables for the painter.
  void initializePainter(Canvas canvas, Size size) {
    this.canvas = canvas;
    this.size = size;

    yTop = paddingTopBottom;
    yBottom = size.height - paddingTopBottom;

    isDark = Theme.of(context).brightness == Brightness.dark;
  }

  /// Draws the axes of the coordinate system.
  void drawCoordSystem() {
    final paintMainAxes = Paint()
      ..color = isDark || isProblem ? Colors.white : Colors.black
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    // Y-axis
    final x = paddingLeft;
    canvas.drawLine(
      Offset(x, yTop),
      Offset(x, yBottom),
      paintMainAxes,
    );

    // X-axis
    canvas.drawLine(
      Offset(paddingLeft, yBottom),
      Offset(size.width - paddingRight, yBottom),
      paintMainAxes,
    );

    final paintHorizontalLine = Paint()
      ..color = isDark || isProblem ? Colors.white : Colors.black
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    int dashWidth = 4;
    int dashSpace = 4;
    double startX = paddingLeft;
    double y = (yBottom + yTop) / 2;

    // Paint dashed horizontal line
    while (startX + dashWidth < size.width - paddingRight) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paintHorizontalLine);

      startX += dashWidth + dashSpace;
    }

    // Paint shorter line to fill the gap at the end
    final horizontalGap = size.width - paddingRight - startX;
    if (horizontalGap > 0) canvas.drawLine(Offset(startX, y), Offset(startX + horizontalGap, y), paintHorizontalLine);

    // Paint vertical dashed lines
    const verticalLinesNumber = 5;

    final paintVerticalLine = Paint()
      ..color = isDark || isProblem ? Colors.white : Colors.black
      ..strokeWidth = 0.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    dashWidth = 3;
    dashSpace = 3;

    for (int i = 1; i <= verticalLinesNumber; i++) {
      double x = paddingLeft + (((size.width - paddingRight - paddingLeft) / (verticalLinesNumber)) * i);
      double yStart = yTop;

      while (yStart + dashWidth < yBottom) {
        canvas.drawLine(Offset(x, yStart), Offset(x, yStart + dashWidth), paintVerticalLine);

        yStart += dashWidth + dashSpace;
      }

      // Paint shorter line to fill the gap at the end
      final verticalGap = yBottom - dashWidth - yStart;
      if (verticalGap > 0) canvas.drawLine(Offset(x, yStart), Offset(x, yStart + verticalGap), paintHorizontalLine);
    }
  }

  /// Draws labels for the x-axis and y-axis.
  void drawCoordSystemLabels() {
    final TextStyle labelTextStyle = TextStyle(
      color: isDark || isProblem ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6),
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
      ..color = isProblem ? Colors.white : CI.blue
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;
    Paint paintCircle = Paint()
      ..color = isProblem ? Colors.white : CI.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.fill;

    const circleSize = 5.0;

    Map<double, double> nulledPercentages = {};

    for (final entry in percentages.entries) {
      nulledPercentages[entry.key - percentages.entries.toList()[0].key] = entry.value;
    }

    for (final entry in nulledPercentages.entries) {
      // Calculate the coordinates of the current history data
      final percentage = entry.value;
      final x =
          paddingLeft + (entry.key / nulledPercentages.keys.toList().last) * (size.width - paddingRight - paddingLeft);
      final y = size.height - paddingTopBottom - percentage * (size.height - paddingTopBottom - paddingTopBottom);

      if (entry.key == nulledPercentages.entries.last.key) {
        canvas.drawCircle(Offset(x, y), circleSize, paintCircle);
      } else {
        // Get next history data to draw a line to
        final nextIndex = nulledPercentages.keys.toList().indexOf(entry.key) + 1;
        final nextTimestamp = nulledPercentages.keys.toList()[nextIndex];
        final nextPercentage = nulledPercentages.values.toList()[nextIndex];
        final nextX = paddingLeft +
            (nextTimestamp / nulledPercentages.keys.toList().last) * (size.width - paddingRight - paddingLeft);
        final nextY =
            size.height - paddingTopBottom - nextPercentage * (size.height - paddingTopBottom - paddingTopBottom);
        canvas.drawLine(Offset(x, y), Offset(nextX, nextY), paintLine);
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
  /// Which time period to display.
  final StatusHistoryTime time;

  /// If the card should be highlighted as a problematic.
  final bool isProblem;

  const StatusHistoryChart({super.key, required this.time, required this.isProblem});

  @override
  StatusHistoryChartState createState() => StatusHistoryChartState();
}

class StatusHistoryChartState extends State<StatusHistoryChart> {
  /// The associated status history service, which is injected by the provider.
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
    if (statusHistory.isLoading) return Container();
    if (statusHistory.hadError) {
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Align(
          alignment: Alignment.center,
          child: Small(
            text: 'Fehler beim Laden der Daten.',
            context: context,
          ),
        ),
      );
    }

    if (widget.time == StatusHistoryTime.day && statusHistory.dayPercentages.isEmpty) return Container();
    if (widget.time == StatusHistoryTime.week && statusHistory.weekPercentages.isEmpty) return Container();

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      // Place RepaintBoundary here to prevent unnecessary repainting.
      child: RepaintBoundary(
        child: CustomPaint(
          painter: StatusHistoryPainter(
            context: context,
            percentages:
                widget.time == StatusHistoryTime.day ? statusHistory.dayPercentages : statusHistory.weekPercentages,
            time: widget.time,
            isProblem: widget.isProblem,
          ),
        ),
      ),
    );
  }
}
