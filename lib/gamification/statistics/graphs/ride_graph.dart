import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RideStatisticsGraph extends StatelessWidget {
  final Widget Function(double value, TitleMeta meta) getTitlesX;

  final Function(int? index) handleBarToucH;

  final double maxY;

  final List<double> yValues;

  final double barWidth;

  final int? selectedBar;

  final Color barColor;

  const RideStatisticsGraph({
    Key? key,
    required this.getTitlesX,
    required this.maxY,
    required this.handleBarToucH,
    required this.yValues,
    required this.barWidth,
    this.selectedBar,
    required this.barColor,
  }) : super(key: key);

  BarChartGroupData createBar({required int x, bool? selected, double? y, double width = 20}) {
    y ??= Random().nextInt(20).toDouble();
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: (selected ?? true) ? barColor : barColor.withOpacity(0.25),
          width: width,
        ),
      ],
    );
  }

  List<BarChartGroupData> getBars() {
    return yValues
        .mapIndexed((i, d) => createBar(
              x: i,
              y: d,
              width: barWidth,
              selected: selectedBar == null ? null : (selectedBar == i),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
              handleBuiltInTouches: false,
              touchCallback: (p0, p1) {
                if (p0 is FlTapUpEvent) {
                  handleBarToucH(p1?.spot?.touchedBarGroupIndex);
                }
              },
              touchExtraThreshold: const EdgeInsets.all(8)),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  axisSide: AxisSide.left,
                  space: 4,
                  child: Text(
                    meta.formattedValue,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                reservedSize: 30,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                getTitlesWidget: getTitlesX,
                showTitles: true,
                reservedSize: 27,
              ),
            ),
          ),
          maxY: maxY == 0 ? 1 : maxY,
          gridData: FlGridData(drawVerticalLine: false),
          barGroups: getBars(),
        ),
        swapAnimationDuration: Duration.zero,
      ),
    );
  }
}
